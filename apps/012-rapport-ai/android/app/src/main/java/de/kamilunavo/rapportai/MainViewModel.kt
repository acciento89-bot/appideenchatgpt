package de.kamilunavo.rapportai

import android.app.Application
import android.net.Uri
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import de.kamilunavo.rapportai.data.RapportRepository
import de.kamilunavo.rapportai.model.*
import de.kamilunavo.rapportai.network.RapportService
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

data class RapportUiState(
    val draft: Rapport = Rapport(),
    val reports: List<Rapport> = emptyList(),
    val templates: List<WorkTemplate> = emptyList(),
    val storageBlocked: Boolean = false,
    val profile: CompanyProfile = CompanyProfile(),
    val usedThisMonth: Int = 0,
    val isPro: Boolean = false,
    val isGenerating: Boolean = false,
    val isRecording: Boolean = false,
    val message: String? = null
) {
    val freeLimit = 5
    val remaining = (freeLimit - usedThisMonth).coerceAtLeast(0)
    val mayGenerate = isPro || usedThisMonth < freeLimit
}

class MainViewModel(application: Application) : AndroidViewModel(application) {
    private val repository = RapportRepository(application)
    private val service = RapportService()
    private val _state = MutableStateFlow(
        RapportUiState(
            profile = repository.loadProfile(),
            usedThisMonth = repository.usedThisMonth(),
            isPro = repository.isPro()
        )
    )
    val state: StateFlow<RapportUiState> = _state.asStateFlow()
    init { reloadWorkspace() }

    private fun workMessage(de: String, en: String) = if (java.util.Locale.getDefault().language == "de") de else en
    fun reloadWorkspace() {
        runCatching { repository.loadWorkspace() }.onSuccess { workspace ->
            _state.value = _state.value.copy(reports = workspace.reports, templates = workspace.templates, storageBlocked = false)
        }.onFailure {
            _state.value = _state.value.copy(storageBlocked = true, message = workMessage("Lokale Daten können nicht gelesen werden. Die vorhandenen Dateien bleiben erhalten. Nach Beheben erneut laden.", "Local data could not be read. Existing files are preserved. Retry after resolving the problem."))
        }
    }

    private fun mutateWorkspace(action: () -> WorkWorkspace): WorkWorkspace? {
        if (_state.value.storageBlocked) { reloadWorkspace(); if (_state.value.storageBlocked) return null }
        return runCatching(action).onSuccess { workspace ->
            _state.value = _state.value.copy(reports = workspace.reports, templates = workspace.templates)
        }.onFailure {
            showMessage(workMessage("Nicht gespeichert. Bitte Eingaben und lokalen Speicher prüfen. Der Entwurf und bestehende Daten bleiben erhalten.", "Not saved. Check the entries and local storage. Your draft and existing data are preserved."))
        }.getOrNull()
    }

    fun updateDraft(update: (Rapport) -> Rapport) {
        _state.value = _state.value.copy(draft = update(_state.value.draft))
    }

    fun setRecording(recording: Boolean) { _state.value = _state.value.copy(isRecording = recording) }
    fun showMessage(message: String) { _state.value = _state.value.copy(message = message) }
    fun clearMessage() { _state.value = _state.value.copy(message = null) }

    fun generate() {
        val current = _state.value
        if (!current.mayGenerate) {
            showMessage("Deine fünf kostenlosen KI-Rapporte sind für diesen Monat verbraucht.")
            return
        }
        if (current.draft.rawText.isBlank()) {
            showMessage("Bitte zuerst den Baustellenbericht einsprechen oder eingeben.")
            return
        }
        _state.value = current.copy(isGenerating = true, message = null)
        viewModelScope.launch {
            runCatching { service.generate(_state.value.draft) }
                .onSuccess { report ->
                    val used = if (_state.value.isPro) _state.value.usedThisMonth else repository.recordGeneration()
                    _state.value = _state.value.copy(
                        draft = _state.value.draft.copy(reportText = report),
                        usedThisMonth = used,
                        isGenerating = false
                    )
                }
                .onFailure { error ->
                    _state.value = _state.value.copy(isGenerating = false, message = error.message ?: "Der Rapport konnte nicht erstellt werden.")
                }
        }
    }

    fun saveDraft(): Rapport? {
        val draft = _state.value.draft
        if (draft.reportText.isBlank() && draft.rawText.isBlank() && draft.workItems.isEmpty()) {
            showMessage(workMessage("Zuerst Text oder Arbeitspositionen eingeben.", "Enter text or work line items first.")); return null
        }
        val workspace = mutateWorkspace { repository.save(draft) } ?: return null
        val saved = workspace.reports.first { it.id == draft.id }
        _state.value = _state.value.copy(draft = saved)
        return saved
    }

    fun saveTemplate(name: String): Boolean = runCatching {
        WorkTemplate(name, _state.value.draft.trade, _state.value.draft.workItems)
    }.fold({ template -> mutateWorkspace { repository.saveTemplate(template) } != null }, {
        showMessage(workMessage("Name und mindestens eine gültige Position erforderlich.", "A name and at least one valid line item are required.")); false
    })
    fun deleteTemplate(id: String): Boolean = mutateWorkspace { repository.deleteTemplate(id) } != null
    fun acknowledge(reportID: String, revisionID: String, name: String, note: String): Boolean =
        mutateWorkspace { repository.acknowledge(reportID, revisionID, name, note) } != null
    fun applyTemplate(template: WorkTemplate): Boolean {
        val current = _state.value.draft
        if (current.workItems.size + template.lines.size > 1000) {
            showMessage(workMessage("Höchstens 1000 Positionen je Rapport.", "At most 1000 entries per report.")); return false
        }
        updateDraft { it.copy(trade = template.trade, workItems = it.workItems + template.instantiate()) }; return true
    }
    fun open(report: Rapport) { _state.value = _state.value.copy(draft = report) }
    fun newDraft() { _state.value = _state.value.copy(draft = Rapport()) }
    fun delete(id: String) { mutateWorkspace { repository.delete(id) } }

    fun updateProfile(profile: CompanyProfile) {
        repository.saveProfile(profile)
        _state.value = _state.value.copy(profile = profile)
    }

    fun importLogo(uri: Uri) {
        viewModelScope.launch {
            runCatching {
                withContext(Dispatchers.IO) {
                    val file = File(getApplication<Application>().filesDir, "company-logo")
                    getApplication<Application>().contentResolver.openInputStream(uri)?.use { input ->
                        file.outputStream().use(input::copyTo)
                    } ?: error("Logo konnte nicht gelesen werden.")
                    file.absolutePath
                }
            }.onSuccess { path -> updateProfile(_state.value.profile.copy(logoPath = path)) }
                .onFailure { showMessage("Das Firmenlogo konnte nicht importiert werden.") }
        }
    }

    fun removeLogo() {
        _state.value.profile.logoPath?.let { runCatching { File(it).delete() } }
        updateProfile(_state.value.profile.copy(logoPath = null))
    }

    fun setPro(active: Boolean) {
        repository.setPro(active)
        _state.value = _state.value.copy(isPro = active)
    }
}
