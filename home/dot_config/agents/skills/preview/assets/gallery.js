'use strict';

let data = JSON.parse(document.getElementById('preview-data').textContent);
const $ = selector => document.querySelector(selector);
const storageKey = 'agent-preview:' + data.token;
let storage;
let saved = {};
try {
  storage = window.localStorage;
  saved = JSON.parse(storage.getItem(storageKey) || '{}') || {};
} catch { storage = null; }
const reviews = new Map(Object.entries(saved.reviews || {}));
const notes = new Map(Object.entries(saved.notes || {}));
let general = saved.general || '';
let requirements = saved.requirements || '';
let combinations = Array.isArray(saved.combinations) ? saved.combinations : [];
const combining = new Set(saved.combining || []);
let combinationNotes = saved.combinationNotes || '';
let lastSubmission = saved.lastSubmission || null;
let viewing = null;
let pinning = false;
let sending = false;

function allOptions() {
  return data.questions.flatMap(question => question.options.map(option => ({ question, option })));
}

function reviewFor(id) {
  if (!reviews.has(id)) reviews.set(id, { status: 'unreviewed', comment: '', annotations: [] });
  return reviews.get(id);
}

function persist() {
  try {
    storage?.setItem(storageKey, JSON.stringify({ reviews: Object.fromEntries(reviews),
      notes: Object.fromEntries(notes), general, requirements, combinations,
      combining: [...combining], combinationNotes, lastSubmission }));
  } catch { say('Browser storage is full. Keep this page open until you submit.'); }
}

function say(text) {
  $('#status').textContent = text;
  $('#viewer-status').textContent = text;
}

function element(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
}

function button(text, action, className = '') {
  const node = element('button', className, text);
  node.type = 'button';
  node.onclick = action;
  return node;
}

function assetUrl(option) {
  return '/asset/' + encodeURIComponent(option.id) + '?token=' + encodeURIComponent(data.token) + '&revision=' + data.revision;
}

function media(option, interactive = false) {
  const node = element(option.kind === 'html' ? 'iframe' : 'img', 'media');
  node.src = assetUrl(option);
  if (option.kind === 'html') {
    // The asset response permits only the annotation bridge unless scripts are enabled.
    node.setAttribute('sandbox', 'allow-scripts');
    node.title=option.label;
    if (!interactive) node.tabIndex = -1;
  } else node.alt = option.label;
  if (!interactive) node.loading = 'lazy';
  return node;
}

function hasFeedback(option) {
  const review = reviewFor(option.id);
  return review.status !== 'unreviewed' || review.comment.trim() || review.annotations.length;
}

function updateProgress() {
  const count = allOptions().filter(({ option }) => hasFeedback(option)).length;
  say(count + ' of ' + allOptions().length + ' options reviewed. Draft stays here until you submit.');
  data.questions.forEach(question => {
    document.getElementById('step-' + question.id)?.classList.toggle('done', question.options.some(hasFeedback));
  });
}

function syncOption(id) {
  const review = reviewFor(id);
  const card = document.getElementById('card-' + id);
  if (card) {
    card.dataset.status = review.status;
    card.querySelector('.approve').setAttribute('aria-pressed', String(review.status === 'approved'));
    card.querySelector('.reject').setAttribute('aria-pressed', String(review.status === 'rejected'));
    card.querySelector('.combine input').checked = combining.has(id);
    card.querySelector('.pin-count').textContent = review.annotations.length ? review.annotations.length + ' pinned comments' : '';
    card.querySelector('textarea').value = review.comment;
  }
  if (viewing?.option.id === id) {
    $('#viewer-approve').setAttribute('aria-pressed', String(review.status === 'approved'));
    $('#viewer-reject').setAttribute('aria-pressed', String(review.status === 'rejected'));
    $('#viewer-comment').value = review.comment;
    $('#viewer-combine').checked = combining.has(id);
  }
}

function setStatus(question, option, status) {
  const review = reviewFor(option.id);
  const next = review.status === status ? 'unreviewed' : status;
  if (next === 'approved' && question.select === 'one') {
    question.options.forEach(other => {
      if (reviewFor(other.id).status === 'approved') {
        reviewFor(other.id).status = 'unreviewed';
        syncOption(other.id);
      }
    });
  }
  review.status = next;
  syncOption(option.id);
  persist();
  updateProgress();
}

function combine(id, checked) {
  if (checked) combining.add(id);
  else combining.delete(id);
  syncOption(id);
  renderCombinations();
  persist();
}

function renderQuestion(question, index) {
  const section = element('section', 'question');
  section.id = 'q-' + question.id;
  section.append(element('h2', '', (index + 1) + '. ' + question.title));
  if (question.prompt) section.append(element('p', 'description', question.prompt));
  section.append(element('p', 'hint', question.select === 'one'
    ? 'Approve one direction, or combine ideas. You can reject or comment on any option.'
    : 'Approve any options that fit. You can reject, comment, or combine ideas.'));
  const grid = element('div', 'grid');
  question.options.forEach(option => {
    const review = reviewFor(option.id);
    const card = element('article', 'card');
    card.id = 'card-' + option.id;
    card.dataset.status = review.status;
    card.setAttribute('aria-label', option.label);
    const frame = element('div', 'frame');
    const expand = button('View larger', () => openViewer(option.id), 'expand');
    expand.setAttribute('aria-label', 'View ' + option.label);
    frame.append(media(option), expand);
    const body = element('div', 'card-body');
    const heading = element('div', 'card-heading');
    heading.append(element('h3', '', option.label), element('span', 'badge', option.kind === 'html' ? 'PAGE' : 'IMAGE'));
    body.append(heading);
    if (option.description) body.append(element('p', 'description', option.description));
    const actions = element('div', 'actions');
    for (const [status, label, className] of [['approved', 'Approve', 'approve'], ['rejected', 'Reject', 'reject']]) {
      const control = button(label, () => setStatus(question, option, status), className);
      control.setAttribute('aria-pressed', String(review.status === status));
      actions.append(control);
    }
    const commentLabel = element('label', '', 'Comment');
    commentLabel.htmlFor = 'comment-' + option.id;
    const comment = element('textarea');
    comment.id = commentLabel.htmlFor;
    comment.maxLength = 4000;
    comment.value = review.comment;
    comment.oninput = () => { review.comment = comment.value; persist(); updateProgress(); };
    const label = element('label', 'combine');
    const checkbox = element('input');
    checkbox.type = 'checkbox';
    checkbox.checked = combining.has(option.id);
    checkbox.onchange = () => combine(option.id, checkbox.checked);
    label.append(checkbox, document.createTextNode('Combine'));
    const pins = element('span', 'pin-count', review.annotations.length ? review.annotations.length + ' pinned comments' : '');
    body.append(actions, commentLabel, comment, label, pins);
    card.append(frame, body);
    grid.append(card);
  });
  const details = element('details');
  details.append(element('summary', '', 'Notes for this question'));
  const note = element('textarea');
  note.setAttribute('aria-label', 'Notes for ' + question.title);
  note.maxLength = 4000;
  note.value = notes.get(question.id) || '';
  note.oninput = () => { notes.set(question.id, note.value); persist(); };
  details.append(note);
  section.append(grid, details);
  return section;
}

function renderCombinations() {
  const labels = new Map(allOptions().map(({ option }) => [option.id, option.label]));
  $('#combination-picks').textContent = combining.size
    ? [...combining].map(id => labels.get(id)).join(' + ')
    : 'Use “Combine” on any options above.';
  $('#add-combination').disabled = combining.size < 2;
  $('#combinations').replaceChildren(...combinations.map((combination, index) => {
    const item = element('div', 'combination');
    item.append(element('strong', '', combination.ids.map(id => labels.get(id)).join(' + ')));
    if (combination.notes) item.append(element('p', '', combination.notes));
    item.append(button('Remove combination', () => {
      combinations.splice(index, 1);
      persist();
      renderCombinations();
    }));
    return item;
  }));
}

function render() {
  document.title = data.title;
  $('#title').textContent = data.title;
  $('#steps').replaceChildren(...data.questions.map((question, index) => {
    const item = element('li');
    const control = button((index + 1) + '. ' + question.title, () => document.getElementById('q-' + question.id).scrollIntoView());
    control.id = 'step-' + question.id;
    item.append(control);
    return item;
  }));
  $('#sections').replaceChildren(...data.questions.map(renderQuestion));
  $('#general-notes').value = general;
  $('#requirements').value = requirements;
  $('#combination-notes').value = combinationNotes;
  renderCombinations();
  updateProgress();
}

function setPinning(enabled) {
  pinning = enabled;
  $('#viewer-pin').setAttribute('aria-pressed', String(enabled));
  $('#pin-hint').hidden = !enabled;
  $('#viewer-stage').classList.toggle('annotating', enabled);
  $('#viewer-stage iframe')?.contentWindow.postMessage({ type: 'preview:pin-mode', enabled }, '*');
}

function renderAnnotations() {
  const review = reviewFor(viewing.option.id);
  $('#viewer-annotations').replaceChildren(...review.annotations.map((annotation, index) => {
    const item = element('div', 'annotation');
    const label = element('label', '', 'Pin ' + (index + 1) + ': ' + (annotation.anchor.text || 'Image point'));
    label.htmlFor = 'annotation-' + index;
    const input = element('textarea');
    input.id = label.htmlFor;
    input.maxLength = 4000;
    input.value = annotation.comment;
    input.placeholder = 'What should change here?';
    input.oninput = () => { annotation.comment = input.value; persist(); updateProgress(); };
    item.append(label, input, button('Remove pin', () => {
      review.annotations.splice(index, 1);
      persist();
      syncOption(viewing.option.id);
      renderAnnotations();
      updateProgress();
    }));
    return item;
  }));
}

function addAnnotation(anchor) {
  const review = reviewFor(viewing.option.id);
  if (review.annotations.length >= 30) { say('This option already has 30 pins. Remove one before adding another.'); return; }
  review.annotations.push({ anchor, comment: '' });
  setPinning(false);
  renderAnnotations();
  syncOption(viewing.option.id);
  persist();
  updateProgress();
  $('#viewer-annotations .annotation:last-child textarea').focus();
}

function pinImage(event) {
  if (!pinning || viewing.option.kind !== 'image') return;
  const image = event.currentTarget;
  const box = image.getBoundingClientRect();
  const scale = Math.min(box.width / image.naturalWidth, box.height / image.naturalHeight);
  const width = image.naturalWidth * scale;
  const height = image.naturalHeight * scale;
  const x = (event.clientX - box.left - (box.width - width) / 2) / width;
  const y = (event.clientY - box.top - (box.height - height) / 2) / height;
  if (x >= 0 && x <= 1 && y >= 0 && y <= 1) addAnnotation({ kind: 'point', x, y });
}

function showViewer() {
  setPinning(false);
  const { question, option } = viewing;
  const options = allOptions();
  $('#viewer-title').textContent = option.label;
  $('#viewer-question').textContent = question.title;
  $('#viewer-position').textContent = (options.findIndex(entry => entry.option.id === option.id) + 1) + ' / ' + options.length;
  $('#viewer-raw').href = assetUrl(option);
  const preview = media(option, true);
  if (option.kind === 'image') preview.onclick = pinImage;
  else preview.onload = () => setPinning(pinning);
  $('#viewer-stage').replaceChildren(preview);
  syncOption(option.id);
  renderAnnotations();
  $('#viewer .feedback').scrollTop = 0;
}

function openViewer(id) {
  viewing = allOptions().find(entry => entry.option.id === id);
  showViewer();
  $('#viewer').showModal();
}

function step(delta) {
  const options = allOptions();
  const index = options.findIndex(entry => entry.option.id === viewing.option.id);
  viewing = options[(index + delta + options.length) % options.length];
  showViewer();
}

async function closeViewer() {
  setPinning(false);
  if (document.fullscreenElement) await document.exitFullscreen().catch(() => {});
  $('#viewer').classList.remove('fullscreen');
  $('#viewer-fullscreen').setAttribute('aria-pressed', 'false');
  $('#viewer-fullscreen').textContent = 'Fullscreen';
  $('#viewer').close();
}

$('#browse').onclick = () => openViewer(allOptions()[0].option.id);
$('#viewer-prev').onclick = () => step(-1);
$('#viewer-next').onclick = () => step(1);
$('#viewer-close').onclick = closeViewer;
$('#viewer').addEventListener('cancel', event => { event.preventDefault(); closeViewer(); });
$('#viewer').addEventListener('keydown', event => {
  if (event.target.closest('textarea,input,select,[contenteditable]')) return;
  if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
    event.preventDefault();
    step(event.key === 'ArrowLeft' ? -1 : 1);
  }
});
$('#viewer-fullscreen').onclick = async () => {
  const dialog = $('#viewer');
  const expanded = !dialog.classList.contains('fullscreen');
  dialog.classList.toggle('fullscreen', expanded);
  $('#viewer-fullscreen').setAttribute('aria-pressed', String(expanded));
  $('#viewer-fullscreen').textContent = expanded ? 'Exit fullscreen' : 'Fullscreen';
  if (expanded && dialog.requestFullscreen) await dialog.requestFullscreen().catch(() => {});
  else if (document.fullscreenElement) await document.exitFullscreen().catch(() => {});
};
document.addEventListener('fullscreenchange', () => {
  if (!document.fullscreenElement) {
    $('#viewer').classList.remove('fullscreen');
    $('#viewer-fullscreen').setAttribute('aria-pressed', 'false');
    $('#viewer-fullscreen').textContent = 'Fullscreen';
  }
});
$('#viewer-feedback').onclick = () => {
  const hidden = $('#viewer-body').classList.toggle('feedback-hidden');
  $('#viewer-feedback').setAttribute('aria-pressed', String(!hidden));
  if (hidden) setPinning(false);
};
$('#viewer-approve').onclick = () => setStatus(viewing.question, viewing.option, 'approved');
$('#viewer-reject').onclick = () => setStatus(viewing.question, viewing.option, 'rejected');
$('#viewer-comment').oninput = event => {
  reviewFor(viewing.option.id).comment = event.target.value;
  syncOption(viewing.option.id);
  persist();
  updateProgress();
};
$('#viewer-combine').onchange = event => combine(viewing.option.id, event.target.checked);
$('#viewer-pin').onclick = () => setPinning(!pinning);
window.addEventListener('message', event => {
  if (!pinning || !viewing || event.source !== $('#viewer-stage iframe')?.contentWindow) return;
  const anchor = event.data?.anchor;
  if (event.data?.type !== 'preview:annotation' || anchor?.kind !== 'element') return;
  if (typeof anchor.selector !== 'string' || !anchor.selector || anchor.selector.length > 1000) return;
  if (typeof anchor.text !== 'string' || anchor.text.length > 500) return;
  const normalized = { kind: 'element', selector: anchor.selector, text: anchor.text };
  if (anchor.matchIndex !== undefined) {
    if (!Number.isSafeInteger(anchor.matchIndex) || anchor.matchIndex < 0) return;
    normalized.matchIndex = anchor.matchIndex;
  }
  addAnnotation(normalized);
});
$('#viewer-notes').onclick = async () => { await closeViewer(); $('#finish').scrollIntoView(); $('#general-notes').focus(); };
$('#general-notes').oninput = event => { general = event.target.value; persist(); };
$('#requirements').oninput = event => { requirements = event.target.value; persist(); };
$('#combination-notes').oninput = event => { combinationNotes = event.target.value; persist(); };
$('#add-combination').onclick = () => {
  if (combining.size < 2) return;
  if (combinations.length >= 50) { say('There are already 50 combinations. Remove one before adding another.'); return; }
  combinations.push({ ids: [...combining], notes: combinationNotes });
  combining.clear();
  combinationNotes = '';
  $('#combination-notes').value = '';
  allOptions().forEach(({ option }) => syncOption(option.id));
  renderCombinations();
  persist();
};

function submission(action) {
  const answers = Object.fromEntries(data.questions.map(question => [question.id, {
    ids: question.options.filter(option => reviewFor(option.id).status === 'approved').map(option => option.id),
    notes: notes.get(question.id) || '',
  }]));
  const currentCombinations = [...combinations];
  if (combining.size >= 2) currentCombinations.push({ ids: [...combining], notes: combinationNotes });
  return { action, revision: data.revision, ids: Object.values(answers).flatMap(answer => answer.ids),
    notes: general, requirements, answers,
    reviews: Object.fromEntries(allOptions().map(({ option }) => [option.id, reviewFor(option.id)])),
    combinations: currentCombinations };
}

async function submit(action) {
  if (sending) return;
  if (combining.size === 1 || (!combining.size && combinationNotes.trim())) {
    say('Choose at least two options for the combination, or clear its draft.');
    await closeViewer();
    $('#finish').scrollIntoView();
    return;
  }
  const payload = submission(action);
  if (action === 'review' && !allOptions().some(({ option }) => hasFeedback(option)) &&
      !general.trim() && !requirements.trim() && ![...notes.values()].some(note => note.trim()) && !payload.combinations.length) {
    say('Add a choice, comment, or note before submitting.');
    return;
  }
  const fingerprint = JSON.stringify(payload);
  if (lastSubmission?.fingerprint !== fingerprint) {
    lastSubmission = { fingerprint, id: Date.now().toString(36) + '-' + Math.random().toString(36).slice(2) };
    persist();
  }
  sending = true;
  for (const id of ['submit', 'viewer-send', 'more']) document.getElementById(id).disabled = true;
  say('Sending feedback…');
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15000);
  try {
    const response = await fetch('/submit', { method: 'POST', signal: controller.signal,
      headers: { 'content-type': 'application/json', 'x-preview-token': data.token },
      body: JSON.stringify({ ...payload, submissionId: lastSubmission.id }) });
    const result = await response.json();
    if (!response.ok) { say('Could not send: ' + result.error + '. Your draft is still here.'); return; }
    say('Sent. Feedback #' + result.seq + ' is saved for the agent.');
  } catch { say('Could not confirm delivery. Your draft is saved. Try Submit again.'); }
  finally {
    clearTimeout(timeout);
    sending = false;
    for (const id of ['submit', 'viewer-send', 'more']) document.getElementById(id).disabled = false;
  }
}
$('#submit').onclick = () => submit('review');
$('#viewer-send').onclick = () => submit('review');
$('#more').onclick = () => submit('more');

function pruneDraft() {
  const valid = new Set(allOptions().map(({ option }) => option.id));
  for (const id of reviews.keys()) if (!valid.has(id)) reviews.delete(id);
  for (const id of combining) if (!valid.has(id)) combining.delete(id);
  for (const id of notes.keys()) if (!data.questions.some(question => question.id === id)) notes.delete(id);
  combinations = combinations.filter(combination => combination.ids.every(id => valid.has(id)));
  for (const question of data.questions) {
    if (question.select !== 'one') continue;
    let approved = false;
    for (const option of question.options) {
      const review = reviewFor(option.id);
      if (review.status !== 'approved') continue;
      if (approved) review.status = 'unreviewed';
      approved = true;
    }
  }
}
const updates = new EventSource('/events?token=' + encodeURIComponent(data.token));
updates.onmessage = event => { if (Number(event.data) > data.revision) $('#refresh').hidden = false; };
$('#refresh').onclick = async () => {
  try {
    const response = await fetch('/config?token=' + encodeURIComponent(data.token));
    if (!response.ok) throw new Error('Could not load config');
    await closeViewer();
    data = { ...(await response.json()), token: data.token };
    pruneDraft();
    persist();
    render();
    $('#refresh').hidden = true;
    say('Options updated. Feedback for unchanged IDs is kept.');
  } catch { say('Could not load new options. Your draft is still here. Try again.'); }
};
pruneDraft();
render();
