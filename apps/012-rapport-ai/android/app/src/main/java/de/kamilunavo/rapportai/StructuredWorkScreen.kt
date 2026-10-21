package de.kamilunavo.rapportai

import android.content.Intent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import de.kamilunavo.rapportai.model.*
import java.text.DateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun StructuredWorkScreen(state: RapportUiState, viewModel: MainViewModel, onBack: () -> Unit, padding: PaddingValues) {
    var editID by rememberSaveable { mutableStateOf<String?>(null) }
    var adding by rememberSaveable { mutableStateOf(false) }
    var deleteID by rememberSaveable { mutableStateOf<String?>(null) }
    var showTemplates by rememberSaveable { mutableStateOf(false) }
    var saveTemplate by rememberSaveable { mutableStateOf(false) }
    var templateName by rememberSaveable { mutableStateOf("") }
    var history by rememberSaveable { mutableStateOf(false) }
    val report = state.draft
    LazyColumn(Modifier.fillMaxSize().padding(padding).imePadding(), contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item { TextButton(onClick = onBack) { Text(stringResource(R.string.work_back)) } }
        item { Text(stringResource(R.string.work_title), style = MaterialTheme.typography.headlineSmall) }
        item { Text(stringResource(R.string.work_facts)) }
        if (state.storageBlocked) item { StorageWarning(viewModel) }
        item { OutlinedTextField(report.reportText, { text -> viewModel.updateDraft { it.copy(reportText = text) } }, Modifier.fillMaxWidth(), label = { Text(stringResource(R.string.work_narrative)) }, minLines = 4) }
        items(report.workItems, key = { it.id }) { item ->
            Card(Modifier.fillMaxWidth()) {
                Column(Modifier.padding(12.dp)) {
                    Text(item.description, style = MaterialTheme.typography.titleMedium)
                    Text(workLine(item))
                    TextButton(onClick = { editID = item.id }) { Text(stringResource(R.string.work_edit)) }
                    TextButton(onClick = { deleteID = item.id }) { Text(stringResource(R.string.work_delete)) }
                }
            }
        }
        item { OutlinedButton(onClick = { adding = true }, enabled = report.workItems.size < 1000, modifier = Modifier.fillMaxWidth()) { Text(stringResource(R.string.work_add)) } }
        item {
            val totals = WorkTotals(report.workItems)
            Text(stringResource(R.string.work_total_minutes, totals.laborMinutes))
            report.workItems.filter { it.kind != WorkKind.LABOR && it.quantity != null }.map { it.kind to it.unit.trim() }.distinct().forEach { (kind, unit) ->
                Text("${kindLabel(kind)}: ${decimalText(totals.quantity(kind, unit).stripTrailingZeros().toPlainString())} $unit")
            }
            Text(stringResource(R.string.work_incomplete, totals.incompleteCount))
        }
        item { OutlinedButton(onClick = { showTemplates = true }, modifier = Modifier.fillMaxWidth()) { Text(stringResource(R.string.work_templates)) } }
        item { OutlinedButton(onClick = { saveTemplate = true }, enabled = report.workItems.isNotEmpty(), modifier = Modifier.fillMaxWidth()) { Text(stringResource(R.string.work_save_template)) } }
        item { Button(onClick = { viewModel.saveDraft() }, enabled = !state.storageBlocked, modifier = Modifier.fillMaxWidth()) { Text(stringResource(R.string.work_save)) } }
        item { OutlinedButton(onClick = { history = true }, enabled = state.reports.any { it.id == report.id }, modifier = Modifier.fillMaxWidth()) { Text(stringResource(R.string.work_history)) } }
    }
    if (adding || editID != null) {
        val existing = report.workItems.firstOrNull { it.id == editID }
        WorkItemDialog(existing, onDismiss = { adding = false; editID = null }) { item ->
            viewModel.updateDraft { current -> current.copy(workItems = if (existing == null) current.workItems + item else current.workItems.map { if (it.id == item.id) item else it }) }
            adding = false; editID = null
        }
    }
    deleteID?.let { id -> ConfirmWorkDelete(onDismiss = { deleteID = null }) { viewModel.updateDraft { it.copy(workItems = it.workItems.filterNot { item -> item.id == id }) }; deleteID = null } }
    if (showTemplates) TemplateDialog(state, viewModel) { showTemplates = false }
    if (saveTemplate) AlertDialog(
        onDismissRequest = { saveTemplate = false }, title = { Text(stringResource(R.string.work_save_template)) },
        text = { Column { Text(stringResource(R.string.work_template_boundary)); OutlinedTextField(templateName, { templateName = it }, label = { Text(stringResource(R.string.work_name)) }) } },
        dismissButton = { TextButton(onClick = { saveTemplate = false }) { Text(stringResource(R.string.work_cancel)) } },
        confirmButton = { TextButton(enabled = templateName.isNotBlank(), onClick = { if (viewModel.saveTemplate(templateName)) { saveTemplate = false; templateName = "" } }) { Text(stringResource(R.string.work_save)) } }
    )
    if (history) WorkHistoryDialog(state, report.id, viewModel) { history = false }
}

@Composable
internal fun StorageWarning(viewModel: MainViewModel) {
    Column { Text(stringResource(R.string.work_load_error), color = MaterialTheme.colorScheme.error); TextButton(onClick = viewModel::reloadWorkspace) { Text(stringResource(R.string.work_retry)) } }
}

@Composable
private fun WorkItemDialog(existing: WorkItem?, onDismiss: () -> Unit, onSave: (WorkItem) -> Unit) {
    var kindName by rememberSaveable(existing?.id) { mutableStateOf((existing?.kind ?: WorkKind.LABOR).name) }
    var description by rememberSaveable(existing?.id) { mutableStateOf(existing?.description ?: "") }
    var unit by rememberSaveable(existing?.id) { mutableStateOf(existing?.unit ?: "min") }
    var amount by rememberSaveable(existing?.id) { mutableStateOf(existing?.minutes?.toString() ?: existing?.quantityValue ?: "") }
    val kind = WorkKind.valueOf(kindName)
    // Parse the visible strings on every edit: invalid or blank values never keep a previous valid number.
    val parsed = runCatching {
        if (kind == WorkKind.LABOR) {
            require(amount.matches(Regex("[0-9]{1,7}")))
            WorkItem.labor(description, amount.toInt())
        } else WorkItem.quantity(kind, description, amount, unit)
    }.getOrNull()?.let { if (existing == null) it else it.copy(id = existing.id) }
    AlertDialog(onDismissRequest = onDismiss, title = { Text(stringResource(R.string.work_item)) }, text = {
        Column(Modifier.verticalScroll(rememberScrollState()).imePadding(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            WorkKind.entries.forEach { option -> FilterChip(selected = kind == option, onClick = { kindName = option.name; amount = ""; unit = if (option == WorkKind.LABOR) "min" else "" }, label = { Text(kindLabel(option)) }) }
            OutlinedTextField(description, { description = it }, label = { Text(stringResource(R.string.work_description)) })
            OutlinedTextField(amount, { amount = it }, label = { Text(stringResource(if (kind == WorkKind.LABOR) R.string.work_minutes else R.string.work_quantity)) }, singleLine = true, isError = parsed == null && amount.isNotEmpty())
            if (kind != WorkKind.LABOR) OutlinedTextField(unit, { unit = it }, label = { Text(stringResource(R.string.work_unit)) }, singleLine = true)
            Text(stringResource(R.string.work_number_help), style = MaterialTheme.typography.bodySmall)
            if (parsed == null) Text(stringResource(R.string.work_invalid), color = MaterialTheme.colorScheme.error)
        }
    }, dismissButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.work_cancel)) } }, confirmButton = { TextButton(enabled = parsed != null, onClick = { parsed?.let(onSave) }) { Text(stringResource(R.string.work_save)) } })
}

@Composable
private fun TemplateDialog(state: RapportUiState, viewModel: MainViewModel, onDismiss: () -> Unit) {
    var deleteID by rememberSaveable { mutableStateOf<String?>(null) }
    AlertDialog(onDismissRequest = onDismiss, title = { Text(stringResource(R.string.work_templates)) }, text = {
        Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(stringResource(R.string.work_template_boundary))
            if (state.templates.isEmpty()) Text(stringResource(R.string.work_no_templates))
            state.templates.forEach { template ->
                Text(template.name, style = MaterialTheme.typography.titleMedium)
                TextButton(onClick = { if (viewModel.applyTemplate(template)) onDismiss() }) { Text(stringResource(R.string.work_use_template)) }
                TextButton(onClick = { deleteID = template.id }) { Text(stringResource(R.string.work_delete)) }
            }
        }
    }, confirmButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.work_close)) } })
    deleteID?.let { id -> ConfirmWorkDelete(onDismiss = { deleteID = null }) { if (viewModel.deleteTemplate(id)) deleteID = null } }
}

@Composable
private fun WorkHistoryDialog(state: RapportUiState, reportID: String, viewModel: MainViewModel, onDismiss: () -> Unit) {
    var revisionID by rememberSaveable { mutableStateOf<String?>(null) }
    val report = state.reports.firstOrNull { it.id == reportID }
    val context = LocalContext.current
    val title = stringResource(R.string.work_history)
    AlertDialog(onDismissRequest = onDismiss, title = { Text(title) }, text = {
        Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(stringResource(R.string.work_saved_only))
            report?.revisions?.reversed()?.forEach { revision -> TextButton(onClick = { revisionID = revision.id }) { Text("${stringResource(R.string.work_revision)} ${revision.number} · ${DateFormat.getDateTimeInstance().format(Date(revision.at))}") } }
            if (report != null) OutlinedButton(onClick = {
                context.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).apply { type = "text/plain"; putExtra(Intent.EXTRA_TEXT, report.structuredWorkText(Locale.getDefault().language == "de")) }, title))
            }) { Text(stringResource(R.string.work_share_history)) }
        }
    }, confirmButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.work_close)) } })
    report?.revisions?.firstOrNull { it.id == revisionID }?.let { revision -> RevisionDialog(report, revision, viewModel) { revisionID = null } }
}

@Composable
private fun RevisionDialog(report: Rapport, revision: WorkRevision, viewModel: MainViewModel, onDismiss: () -> Unit) {
    var acknowledging by rememberSaveable { mutableStateOf(false) }
    AlertDialog(onDismissRequest = onDismiss, title = { Text("${stringResource(R.string.work_revision)} ${revision.number}") }, text = {
        Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(listOf(revision.content.customer, revision.content.location, revision.content.system).joinToString("\n"))
            Text(stringResource(R.string.work_original_notes), style = MaterialTheme.typography.titleSmall)
            Text(revision.content.rawText)
            Text(revision.content.reportText)
            revision.content.workItems.forEach { Text("${it.description}: ${workLine(it)}") }
            report.acknowledgements.filter { it.revisionID == revision.id }.forEach { ack -> Text("${stringResource(R.string.work_ack)}: ${ack.name}\n${ack.note}\n${DateFormat.getDateTimeInstance().format(Date(ack.at))}") }
            Text(stringResource(R.string.work_ack_boundary))
            OutlinedButton(onClick = { acknowledging = true }) { Text(stringResource(R.string.work_record_ack)) }
        }
    }, confirmButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.work_close)) } })
    if (acknowledging) AcknowledgementDialog(report.id, revision.id, viewModel) { acknowledging = false }
}

@Composable
private fun AcknowledgementDialog(reportID: String, revisionID: String, viewModel: MainViewModel, onDismiss: () -> Unit) {
    var name by rememberSaveable(revisionID) { mutableStateOf("") }
    var note by rememberSaveable(revisionID) { mutableStateOf("") }
    var confirmed by rememberSaveable(revisionID) { mutableStateOf(false) }
    AlertDialog(onDismissRequest = onDismiss, title = { Text(stringResource(R.string.work_record_ack)) }, text = {
        Column(Modifier.verticalScroll(rememberScrollState()).imePadding()) {
            Text(stringResource(R.string.work_ack_boundary))
            OutlinedTextField(name, { name = it }, label = { Text(stringResource(R.string.work_name)) })
            OutlinedTextField(note, { note = it }, label = { Text(stringResource(R.string.work_note)) })
            Row { Checkbox(confirmed, { confirmed = it }); Text(stringResource(R.string.work_ack_consent), Modifier.weight(1f)) }
        }
    }, dismissButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.work_cancel)) } }, confirmButton = { TextButton(enabled = name.isNotBlank() && confirmed, onClick = { if (viewModel.acknowledge(reportID, revisionID, name, note)) onDismiss() }) { Text(stringResource(R.string.work_save)) } })
}

@Composable
private fun ConfirmWorkDelete(onDismiss: () -> Unit, onConfirm: () -> Unit) {
    AlertDialog(onDismissRequest = onDismiss, title = { Text(stringResource(R.string.work_delete_question)) }, text = { Text(stringResource(R.string.work_delete_warning)) }, dismissButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.work_cancel)) } }, confirmButton = { TextButton(onClick = onConfirm) { Text(stringResource(R.string.work_delete)) } })
}
@Composable
private fun kindLabel(kind: WorkKind): String = stringResource(when (kind) { WorkKind.LABOR -> R.string.work_labor; WorkKind.MATERIAL -> R.string.work_material; WorkKind.MEASUREMENT -> R.string.work_measurement })
@Composable
private fun workLine(item: WorkItem): String {
    val value = if (item.kind == WorkKind.LABOR) item.minutes?.let { "$it min" } else item.quantityValue?.let { "${decimalText(it)} ${item.unit}" }
    return "${kindLabel(item.kind)} · ${value ?: stringResource(R.string.work_not_entered)}"
}
private fun decimalText(text: String): String = if (Locale.getDefault().language == "de") text.replace('.', ',') else text
