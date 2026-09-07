package de.kamilunavo.rapportai

import android.app.Application
import android.net.Uri
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import de.kamilunavo.rapportai.data.RapportRepository
import de.kamilunavo.rapportai.model.CompanyProfile
import de.kamilunavo.rapportai.model.Rapport
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
            reports = repository.loadReports(),
            profile = repository.loadProfile(),
            usedThisMonth = repository.usedThisMonth(),
            isPro = repository.isPro()
        )
    )
    val state: StateFlow<RapportUiState> = _state.asStateFlow()

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

    fun saveDraft() {
        if (_state.value.draft.reportText.isBlank()) {
            showMessage("Erstelle oder bearbeite zuerst einen fertigen Rapport.")
            return
        }
        val reports = repository.save(_state.value.draft)
        val saved = reports.first { it.id == _state.value.draft.id }
        _state.value = _state.value.copy(draft = saved, reports = reports, message = "Rapport wurde lokal gespeichert.")
    }

    fun open(report: Rapport) { _state.value = _state.value.copy(draft = report) }
    fun newDraft() { _state.value = _state.value.copy(draft = Rapport()) }
    fun delete(id: String) { _state.value = _state.value.copy(reports = repository.delete(id)) }

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
