package de.kamilunavo.rapportai

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Business
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.PictureAsPdf
import androidx.compose.material.icons.filled.Save
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material.icons.filled.Work
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import de.kamilunavo.rapportai.billing.BillingManager
import de.kamilunavo.rapportai.model.CompanyProfile
import de.kamilunavo.rapportai.model.Rapport
import de.kamilunavo.rapportai.model.Tone
import de.kamilunavo.rapportai.model.Trade
import de.kamilunavo.rapportai.pdf.PdfExporter
import de.kamilunavo.rapportai.speech.SpeechController
import de.kamilunavo.rapportai.ui.Cyan
import de.kamilunavo.rapportai.ui.Muted
import de.kamilunavo.rapportai.ui.Navy
import de.kamilunavo.rapportai.ui.Orange
import de.kamilunavo.rapportai.ui.Raised
import de.kamilunavo.rapportai.ui.RapportTheme
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : ComponentActivity() {
    private val viewModel: MainViewModel by viewModels()
    private lateinit var billing: BillingManager
    private lateinit var speech: SpeechController

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        billing = BillingManager(this, viewModel::setPro)
        speech = SpeechController(
            context = this,
            onText = { text -> viewModel.updateDraft { it.copy(rawText = text) } },
            onRecording = viewModel::setRecording,
            onError = viewModel::showMessage
        )
        billing.connect()

        setContent {
            RapportTheme {
                val state by viewModel.state.collectAsStateWithLifecycle()
                val billingState by billing.state.collectAsStateWithLifecycle()
                RapportApp(
                    state = state,
                    billingState = billingState,
                    viewModel = viewModel,
                    onRecord = { if (state.isRecording) speech.stop() else speech.start(state.draft.rawText) },
                    onPurchase = { billing.purchase(this, it) },
                    onRestore = billing::restore,
                    onSharePdf = { sharePdf(it, state.profile) }
                )
                val message = state.message ?: billingState.message
                if (message != null) {
                    AlertDialog(
                        onDismissRequest = { viewModel.clearMessage(); billing.clearMessage() },
                        confirmButton = { TextButton(onClick = { viewModel.clearMessage(); billing.clearMessage() }) { Text("OK") } },
                        title = { Text("Hinweis") },
                        text = { Text(message) }
                    )
                }
            }
        }
    }

    private fun sharePdf(report: Rapport, profile: CompanyProfile) {
        runCatching {
            val file = PdfExporter.create(this, report, profile)
            val uri = FileProvider.getUriForFile(this, "$packageName.files", file)
            startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).apply {
                type = "application/pdf"
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }, "Rapport als PDF teilen"))
        }.onFailure { viewModel.showMessage("Die PDF-Datei konnte nicht erstellt werden.") }
    }

    override fun onDestroy() {
        speech.destroy()
        billing.close()
        super.onDestroy()
    }
}

private enum class AppTab(val title: String, val icon: ImageVector) {
    CREATE("Erstellen", Icons.Default.Mic),
    REPORTS("Rapporte", Icons.Default.Description),
    SETTINGS("Mehr", Icons.Default.Settings)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun RapportApp(
    state: RapportUiState,
    billingState: BillingManager.BillingState,
    viewModel: MainViewModel,
    onRecord: () -> Unit,
    onPurchase: (String) -> Unit,
    onRestore: () -> Unit,
    onSharePdf: (Rapport) -> Unit
) {
    var tab by remember { mutableStateOf(AppTab.CREATE) }
    var showPaywall by remember { mutableStateOf(false) }
    Scaffold(
        containerColor = Navy,
        topBar = {
            TopAppBar(
                title = { Text(if (tab == AppTab.CREATE) "Neuer Rapport" else tab.title, fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Navy, titleContentColor = Color.White),
                actions = {
                    if (tab == AppTab.CREATE && (state.draft.rawText.isNotBlank() || state.draft.reportText.isNotBlank())) {
                        IconButton(onClick = viewModel::newDraft) { Icon(Icons.Default.Add, "Neuen Rapport beginnen") }
                    }
                }
            )
        },
        bottomBar = {
            NavigationBar(containerColor = Raised) {
                AppTab.entries.forEach { item ->
                    NavigationBarItem(
                        selected = tab == item,
                        onClick = { tab = item },
                        icon = { Icon(item.icon, null) },
                        label = { Text(item.title) }
                    )
                }
            }
        }
    ) { padding ->
        when (tab) {
            AppTab.CREATE -> CreateScreen(state, viewModel, onRecord, { showPaywall = true }, onSharePdf, padding)
            AppTab.REPORTS -> ReportsScreen(state, viewModel, onSharePdf, { report -> viewModel.open(report); tab = AppTab.CREATE }, padding)
            AppTab.SETTINGS -> SettingsScreen(state, viewModel, { showPaywall = true }, onRestore, padding)
        }
    }
    if (showPaywall) {
        PaywallDialog(
            state = billingState,
            onDismiss = { showPaywall = false },
            onPurchase = onPurchase,
            onRestore = onRestore
        )
    }
}

@Composable
private fun CreateScreen(
    state: RapportUiState,
    viewModel: MainViewModel,
    onRecord: () -> Unit,
    onPaywall: () -> Unit,
    onSharePdf: (Rapport) -> Unit,
    padding: PaddingValues
) {
    val permissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) onRecord() else viewModel.showMessage("Für das Einsprechen benötigt Rapport AI Zugriff auf das Mikrofon.")
    }
    val context = LocalContext.current
    LazyColumn(
        modifier = Modifier.fillMaxSize().padding(padding),
        contentPadding = PaddingValues(16.dp, 8.dp, 16.dp, 28.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            CraftCard {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(54.dp).background(Navy, RoundedCornerShape(16.dp)), contentAlignment = Alignment.Center) {
                        Icon(Icons.Default.Work, null, tint = Orange, modifier = Modifier.size(30.dp))
                    }
                    Spacer(Modifier.width(14.dp))
                    Column(Modifier.weight(1f)) {
                        Text("HANDWERK → RAPPORT", color = Cyan, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold)
                        Text("Sprich frei. Wir machen es professionell.", fontWeight = FontWeight.Bold)
                        Text(if (state.isPro) "PRO · Unbegrenzte KI-Rapporte" else "Noch ${state.remaining} kostenlose KI-Rapporte diesen Monat", color = Muted, style = MaterialTheme.typography.bodySmall)
                        if (!state.isPro) TextButton(onClick = onPaywall, contentPadding = PaddingValues(0.dp)) { Text("Pro freischalten", color = Orange) }
                    }
                }
            }
        }
        item { ContextCard(state.draft, viewModel::updateDraft) }
        item {
            CraftCard {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.Description, null, tint = Cyan)
                    Spacer(Modifier.width(8.dp))
                    Text("Was wurde gemacht?", fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                    if (state.isRecording) Text("AUFNAHME", color = Color(0xFFFF6B6B), fontWeight = FontWeight.Bold)
                }
                Spacer(Modifier.height(12.dp))
                OutlinedTextField(
                    value = state.draft.rawText,
                    onValueChange = { text -> viewModel.updateDraft { it.copy(rawText = text) } },
                    modifier = Modifier.fillMaxWidth().height(190.dp),
                    placeholder = { Text("Beispiel: Beim Kunden angekommen, Wasser unter der Dusche festgestellt …") },
                    label = { Text("Notizen vom Einsatz") }
                )
                Spacer(Modifier.height(12.dp))
                OutlinedButton(
                    onClick = {
                        if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) onRecord()
                        else permissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
                    },
                    modifier = Modifier.fillMaxWidth().height(50.dp)
                ) {
                    Icon(if (state.isRecording) Icons.Default.Stop else Icons.Default.Mic, null)
                    Spacer(Modifier.width(8.dp))
                    Text(if (state.isRecording) "Aufnahme beenden" else "Rapport einsprechen")
                }
                Spacer(Modifier.height(10.dp))
                Button(
                    onClick = { if (state.mayGenerate) viewModel.generate() else onPaywall() },
                    enabled = !state.isGenerating && state.draft.rawText.isNotBlank(),
                    modifier = Modifier.fillMaxWidth().height(54.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Orange, contentColor = Navy)
                ) {
                    if (state.isGenerating) CircularProgressIndicator(Modifier.size(22.dp), strokeWidth = 2.dp, color = Navy)
                    else { Icon(Icons.Default.AutoAwesome, null); Spacer(Modifier.width(8.dp)); Text("Professionellen Rapport erstellen", fontWeight = FontWeight.Bold) }
                }
            }
        }
        if (state.draft.reportText.isNotBlank()) item {
            CraftCard {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.CheckCircle, null, tint = Cyan)
                    Spacer(Modifier.width(8.dp))
                    Text("Fertiger Rapport", fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                    Text("BEARBEITBAR", color = Orange, style = MaterialTheme.typography.labelSmall)
                }
                Spacer(Modifier.height(12.dp))
                OutlinedTextField(
                    value = state.draft.reportText,
                    onValueChange = { text -> viewModel.updateDraft { it.copy(reportText = text) } },
                    modifier = Modifier.fillMaxWidth().height(270.dp),
                    label = { Text("Rapporttext") }
                )
                Text("Bitte Inhalt, Messwerte und ausgeführte Arbeiten vor Verwendung prüfen.", color = Muted, style = MaterialTheme.typography.bodySmall, modifier = Modifier.padding(top = 8.dp))
                Row(Modifier.fillMaxWidth().padding(top = 12.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    OutlinedButton(onClick = viewModel::saveDraft, modifier = Modifier.weight(1f)) { Icon(Icons.Default.Save, null); Spacer(Modifier.width(6.dp)); Text("Speichern") }
                    OutlinedButton(onClick = { viewModel.saveDraft(); onSharePdf(state.draft) }, modifier = Modifier.weight(1f)) { Icon(Icons.Default.PictureAsPdf, null); Spacer(Modifier.width(6.dp)); Text("PDF teilen") }
                }
            }
        }
    }
}

@Composable
private fun ContextCard(draft: Rapport, update: ((Rapport) -> Rapport) -> Unit) {
    CraftCard {
        Row(verticalAlignment = Alignment.CenterVertically) { Icon(Icons.Default.LocationOn, null, tint = Orange); Spacer(Modifier.width(8.dp)); Text("Einsatz", fontWeight = FontWeight.Bold) }
        Text("Gewerk", color = Muted, style = MaterialTheme.typography.labelMedium, modifier = Modifier.padding(top = 12.dp))
        Row(Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Trade.entries.forEach { trade -> FilterChip(selected = draft.trade == trade, onClick = { update { it.copy(trade = trade) } }, label = { Text(trade.title) }) }
        }
        OutlinedTextField(draft.customer, { text -> update { it.copy(customer = text) } }, Modifier.fillMaxWidth(), label = { Text("Kunde / Auftraggeber") }, singleLine = true)
        OutlinedTextField(draft.location, { text -> update { it.copy(location = text) } }, Modifier.fillMaxWidth(), label = { Text("Einsatzort") }, singleLine = true)
        OutlinedTextField(draft.system, { text -> update { it.copy(system = text) } }, Modifier.fillMaxWidth(), label = { Text("Objekt / Anlage / Bauteil") }, singleLine = true)
        Text("Stil", color = Muted, style = MaterialTheme.typography.labelMedium, modifier = Modifier.padding(top = 10.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Tone.entries.forEach { tone -> FilterChip(selected = draft.tone == tone, onClick = { update { it.copy(tone = tone) } }, label = { Text(tone.title, maxLines = 1) }) }
        }
    }
}

@Composable
private fun ReportsScreen(state: RapportUiState, viewModel: MainViewModel, onSharePdf: (Rapport) -> Unit, onEdit: (Rapport) -> Unit, padding: PaddingValues) {
    var deleteTarget by remember { mutableStateOf<Rapport?>(null) }
    if (state.reports.isEmpty()) {
        Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(Icons.Default.History, null, tint = Cyan, modifier = Modifier.size(54.dp))
                Text("Noch keine Rapporte", fontWeight = FontWeight.Bold, modifier = Modifier.padding(top = 12.dp))
                Text("Gespeicherte Arbeitsrapporte erscheinen hier.", color = Muted)
            }
        }
    } else LazyColumn(Modifier.fillMaxSize().padding(padding), contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        items(state.reports, key = { it.id }) { report ->
            CraftCard {
                Text(report.displayTitle, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
                Text(listOf(report.trade.title, report.location, report.system).filter(String::isNotBlank).joinToString(" · "), color = Muted, maxLines = 2, overflow = TextOverflow.Ellipsis)
                Text(SimpleDateFormat("dd.MM.yyyy, HH:mm", Locale.GERMANY).format(Date(report.updatedAt)), color = Orange, style = MaterialTheme.typography.bodySmall)
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                    TextButton(onClick = { onEdit(report) }) { Text("Bearbeiten") }
                    TextButton(onClick = { onSharePdf(report) }) { Icon(Icons.Default.PictureAsPdf, null); Text(" PDF") }
                    TextButton(onClick = { deleteTarget = report }) { Icon(Icons.Default.Delete, null); Text(" Löschen") }
                }
            }
        }
    }
    deleteTarget?.let { report ->
        AlertDialog(
            onDismissRequest = { deleteTarget = null },
            title = { Text("Rapport löschen?") },
            text = { Text("„${report.displayTitle}“ wird dauerhaft von diesem Gerät entfernt.") },
            dismissButton = { TextButton(onClick = { deleteTarget = null }) { Text("Abbrechen") } },
            confirmButton = { TextButton(onClick = { viewModel.delete(report.id); deleteTarget = null }) { Text("Löschen") } }
        )
    }
}

@Composable
private fun SettingsScreen(state: RapportUiState, viewModel: MainViewModel, onPaywall: () -> Unit, onRestore: () -> Unit, padding: PaddingValues) {
    val context = LocalContext.current
    val logoLauncher = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri -> uri?.let(viewModel::importLogo) }
    LazyColumn(Modifier.fillMaxSize().padding(padding), contentPadding = PaddingValues(16.dp, 8.dp, 16.dp, 28.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        item {
            CraftCard {
                Text("Rapport AI", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                Text("Kamilunavo · Für alle Gewerke", color = Cyan)
                Text("Deine Entwürfe und fertigen Rapporte bleiben lokal auf diesem Gerät.", color = Muted, modifier = Modifier.padding(top = 6.dp))
            }
        }
        item {
            CraftCard {
                Row(verticalAlignment = Alignment.CenterVertically) { Icon(Icons.Default.Business, null, tint = Orange); Spacer(Modifier.width(8.dp)); Text("Firmenprofil für PDF", fontWeight = FontWeight.Bold) }
                ProfileField("Firmenname", state.profile.companyName) { viewModel.updateProfile(state.profile.copy(companyName = it)) }
                ProfileField("Ansprechpartner", state.profile.ownerName) { viewModel.updateProfile(state.profile.copy(ownerName = it)) }
                ProfileField("Anschrift", state.profile.address) { viewModel.updateProfile(state.profile.copy(address = it)) }
                ProfileField("Telefon", state.profile.phone) { viewModel.updateProfile(state.profile.copy(phone = it)) }
                ProfileField("E-Mail", state.profile.email) { viewModel.updateProfile(state.profile.copy(email = it)) }
                OutlinedButton(onClick = { logoLauncher.launch("image/*") }, modifier = Modifier.fillMaxWidth().padding(top = 8.dp)) { Text(if (state.profile.logoPath == null) "Firmenlogo auswählen" else "Firmenlogo ändern") }
                if (state.profile.logoPath != null) TextButton(onClick = viewModel::removeLogo) { Text("Logo entfernen") }
            }
        }
        item {
            CraftCard {
                Text(if (state.isPro) "Rapport AI Pro" else "Kostenloser Tarif", fontWeight = FontWeight.Bold)
                Text(if (state.isPro) "Unbegrenzte KI-Rapporte sind aktiv." else "${state.usedThisMonth} von ${state.freeLimit} KI-Rapporten verwendet", color = if (state.isPro) Cyan else Muted)
                if (!state.isPro) Button(onClick = onPaywall, modifier = Modifier.fillMaxWidth().padding(top = 8.dp)) { Text("Pro ansehen") }
                OutlinedButton(onClick = onRestore, modifier = Modifier.fillMaxWidth().padding(top = 6.dp)) { Text("Käufe wiederherstellen") }
            }
        }
        item {
            CraftCard {
                Text("Datenschutz & Rechtliches", fontWeight = FontWeight.Bold)
                Text("Bei KI-Verarbeitung wird nur der eingegebene Rapportinhalt an den geschützten Dienst übertragen. Keine OpenAI-Zugangsdaten befinden sich in der App.", color = Muted, modifier = Modifier.padding(vertical = 8.dp))
                LegalButton("Datenschutzerklärung", "https://www.kamilunavo.com/privacy", context::startActivity)
                LegalButton("Google Play-Nutzungsbedingungen", "https://play.google.com/about/play-terms/", context::startActivity)
            }
        }
    }
}

@Composable
private fun ProfileField(label: String, value: String, change: (String) -> Unit) {
    OutlinedTextField(value, change, Modifier.fillMaxWidth().padding(top = 7.dp), label = { Text(label) }, singleLine = true)
}

@Composable
private fun LegalButton(label: String, url: String, launch: (Intent) -> Unit) {
    TextButton(onClick = { launch(Intent(Intent.ACTION_VIEW, Uri.parse(url))) }) { Icon(Icons.Default.Email, null); Spacer(Modifier.width(6.dp)); Text(label) }
}

@Composable
private fun PaywallDialog(state: BillingManager.BillingState, onDismiss: () -> Unit, onPurchase: (String) -> Unit, onRestore: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Rapport AI Pro") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text("Unbegrenzte KI-Rapporte, Firmenlogo und professioneller PDF-Export.")
                BillingManager.PRODUCT_IDS.forEach { id ->
                    val product = state.products[id]
                    val price = product?.subscriptionOfferDetails?.firstOrNull()?.pricingPhases?.pricingPhaseList?.firstOrNull()?.formattedPrice
                    Button(onClick = { onPurchase(id) }, enabled = product != null, modifier = Modifier.fillMaxWidth()) {
                        Text((if (id == BillingManager.MONTHLY_ID) "Monatlich" else "Jährlich") + (price?.let { " · $it" } ?: " · wird geladen"))
                    }
                }
                TextButton(onClick = onRestore, modifier = Modifier.align(Alignment.CenterHorizontally)) { Text("Käufe wiederherstellen") }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text("Schließen") } }
    )
}

@Composable
private fun CraftCard(content: @Composable ColumnScope.() -> Unit) {
    Card(Modifier.fillMaxWidth(), shape = RoundedCornerShape(20.dp), colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)) {
        Column(Modifier.fillMaxWidth().padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp), content = content)
    }
}
