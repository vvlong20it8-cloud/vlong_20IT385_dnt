import { Capacitor } from '@capacitor/core';
import './style.css';

// Chrome on the same PC uses localhost.
// Android Emulator uses 10.0.2.2 to reach the host PC.
// For a real phone, replace the Android host with your PC's LAN IP address.
const API_URL = Capacitor.isNativePlatform()
  ? 'http://10.0.2.2/field_survey_api/api.php'
  : 'http://localhost/field_survey_api/api.php';

const $ = (id) => document.getElementById(id);
const state = { surveys: [], editingId: null };

const recordsEl = $('records');
const noticeEl = $('notice');
const dialog = $('surveyDialog');

function todayISO() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
}
function escapeHtml(value = '') {
  return String(value).replace(/[&<>"']/g, (char) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
  })[char]);
}
function showNotice(message, kind = 'info') {
  noticeEl.hidden = false;
  noticeEl.className = `notice ${kind}`;
  noticeEl.textContent = message;
}
function hideNotice() {
  noticeEl.hidden = true;
  noticeEl.textContent = '';
}
async function apiRequest(url = API_URL, options = {}) {
  let response;
  try {
    response = await fetch(url, options);
  } catch {
    throw new Error(`Cannot reach API at ${url}. Start Apache/MySQL and check the PHP API folder.`);
  }
  let result;
  try {
    result = await response.json();
  } catch {
    throw new Error(`API returned a non-JSON response (HTTP ${response.status}). Check PHP errors.`);
  }
  if (!response.ok || result.success !== true) {
    throw new Error(result.message || `API request failed (HTTP ${response.status}).`);
  }
  return result;
}
async function loadSurveys() {
  recordsEl.innerHTML = '<div class="loading"><span class="spinner"></span> Loading surveys...</div>';
  hideNotice();
  try {
    const result = await apiRequest();
    state.surveys = Array.isArray(result.data) ? result.data : [];
    render();
  } catch (error) {
    state.surveys = [];
    updateMetrics();
    recordsEl.innerHTML = `
      <div class="error-card">
        <div class="error-symbol">⌁</div>
        <h3>Could not connect to the API</h3>
        <p>${escapeHtml(error.message)}</p>
        <p class="hint">Import database/field_survey_db.sql, then copy backend/field_survey_api into C:\\xampp\\htdocs\\field_survey_api.</p>
        <button id="retryBtn" class="primary-btn">↻ Try again</button>
      </div>`;
    $('retryBtn').addEventListener('click', loadSurveys);
  }
}
function updateMetrics() {
  $('totalCount').textContent = state.surveys.length;
  $('progressCount').textContent = state.surveys.filter(s => s.status === 'In progress').length;
  $('completedCount').textContent = state.surveys.filter(s => s.status === 'Completed').length;
}
function render() {
  updateMetrics();
  const query = $('searchInput').value.trim().toLowerCase();
  const status = $('statusFilter').value;
  const list = state.surveys.filter(s => {
    const searchable = `${s.location} ${s.surveyor} ${s.notes || ''}`.toLowerCase();
    return searchable.includes(query) && (status === 'All' || s.status === status);
  });
  if (!list.length) {
    recordsEl.innerHTML = `<div class="empty-card"><div class="empty-icon">▤</div><h3>${state.surveys.length ? 'No matching surveys' : 'No surveys yet'}</h3><p>${state.surveys.length ? 'Try another search or status filter.' : 'Create your first field survey to get started.'}</p></div>`;
    return;
  }
  recordsEl.innerHTML = list.map(s => `
    <article class="survey-card">
      <div class="location-icon">⌖</div>
      <div class="survey-main">
        <h3>${escapeHtml(s.location)}</h3>
        <div class="survey-meta">${escapeHtml(s.surveyor)} <span>·</span> ${escapeHtml(s.date || s.survey_date || '')}</div>
        ${s.notes ? `<p class="survey-notes">${escapeHtml(s.notes)}</p>` : ''}
      </div>
      <div class="survey-actions">
        <span class="status status-${s.status === 'Completed' ? 'completed' : s.status === 'In progress' ? 'progress' : 'planned'}">${escapeHtml(s.status)}</span>
        <div class="action-row">
          <button class="small-action" data-edit="${Number(s.id)}" aria-label="Edit survey">✎</button>
          <button class="small-action delete" data-delete="${Number(s.id)}" aria-label="Delete survey">⌫</button>
        </div>
      </div>
    </article>`).join('');
  recordsEl.querySelectorAll('[data-edit]').forEach(button => button.addEventListener('click', () => openEdit(Number(button.dataset.edit))));
  recordsEl.querySelectorAll('[data-delete]').forEach(button => button.addEventListener('click', () => deleteSurvey(Number(button.dataset.delete))));
}
function openNew() {
  state.editingId = null;
  $('surveyForm').reset();
  $('surveyId').value = '';
  $('dialogTitle').textContent = 'New survey';
  $('dateInput').value = todayISO();
  $('statusInput').value = 'Planned';
  dialog.showModal();
}
function openEdit(id) {
  const s = state.surveys.find(item => Number(item.id) === id);
  if (!s) return;
  state.editingId = id;
  $('surveyForm').reset();
  $('surveyId').value = id;
  $('locationInput').value = s.location || '';
  $('surveyorInput').value = s.surveyor || '';
  $('dateInput').value = (s.date || s.survey_date || todayISO()).slice(0, 10);
  $('statusInput').value = s.status || 'Planned';
  $('notesInput').value = s.notes || '';
  $('dialogTitle').textContent = 'Edit survey';
  dialog.showModal();
}
async function saveSurvey(event) {
  event.preventDefault();
  const payload = {
    location: $('locationInput').value.trim(),
    surveyor: $('surveyorInput').value.trim(),
    date: $('dateInput').value,
    status: $('statusInput').value,
    notes: $('notesInput').value.trim()
  };
  const isEdit = state.editingId !== null;
  const url = isEdit ? `${API_URL}?id=${encodeURIComponent(state.editingId)}` : API_URL;
  try {
    await apiRequest(url, {
      method: isEdit ? 'PUT' : 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
    dialog.close();
    showNotice(isEdit ? 'Survey updated successfully.' : 'Survey saved to MySQL.', 'success');
    await loadSurveys();
  } catch (error) {
    showNotice(error.message, 'error');
  }
}
async function deleteSurvey(id) {
  const survey = state.surveys.find(s => Number(s.id) === id);
  if (!survey || !window.confirm(`Delete the survey for "${survey.location}"?`)) return;
  try {
    await apiRequest(`${API_URL}?id=${encodeURIComponent(id)}`, { method: 'DELETE' });
    showNotice('Survey deleted.', 'success');
    await loadSurveys();
  } catch (error) {
    showNotice(error.message, 'error');
  }
}

$('newSurveyBtn').addEventListener('click', openNew);
$('refreshBtn').addEventListener('click', loadSurveys);
$('searchInput').addEventListener('input', render);
$('statusFilter').addEventListener('change', render);
$('surveyForm').addEventListener('submit', saveSurvey);
$('closeDialogBtn').addEventListener('click', () => dialog.close());
$('cancelBtn').addEventListener('click', () => dialog.close());
loadSurveys();
