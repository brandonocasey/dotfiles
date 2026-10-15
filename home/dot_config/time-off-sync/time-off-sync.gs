// Mirrors your BambooHR time off onto your Google Calendar as out-of-office
// events, which Slack's Google Calendar app turns into an out-of-office status.
//
// Setup:
// 1. Services > + > Google Calendar API.
// 2. Project Settings > Script Properties: FEED_URL (a BambooHR "Who's Out"
//    iCal feed link), EMPLOYEE_NAME (your name as BambooHR shows it), and
//    optionally HOLIDAY_FEED_URL (the BambooHR "Company Holidays" feed link).
// 3. Run installTrigger once to sync every hour.

const SYNC_TAG = '(BambooHR)';
const LOOKAHEAD_DAYS = 180;
// The company holiday feed lists every country's holidays with no region field,
// so US holidays are picked by exact name and the MM-DD range they can start
// in. The ranges rule out other countries' holidays with the same name, such
// as North Macedonia's Independence Day on Sep 8. Add new US holidays here.
const US_HOLIDAYS = [
  [/^Memorial Day$/i, '05-25', '05-31'],
  [/^Juneteenth$/i, '06-18', '06-21'],
  [/^Independence Day$/i, '07-02', '07-05'],
  [/^Labor Day$/i, '09-01', '09-07'],
  [/^Thanksgiving( Day)?$/i, '11-22', '11-28'],
  [/^Christmas( Day)?$/i, '12-23', '12-26'],
  [/^New Year['’]?s Day$/i, '12-31', '12-31'],
  [/^New Year['’]?s Day$/i, '01-01', '01-02'],
];

function syncTimeOff() {
  const props = PropertiesService.getScriptProperties();
  const feedUrl = props.getProperty('FEED_URL');
  const name = props.getProperty('EMPLOYEE_NAME');
  const holidayFeedUrl = props.getProperty('HOLIDAY_FEED_URL');
  if (!feedUrl || !name) throw new Error('Set FEED_URL and EMPLOYEE_NAME in Script Properties');

  const tz = CalendarApp.getDefaultCalendar().getTimeZone();
  const today = Utilities.formatDate(new Date(), tz, 'yyyy-MM-dd');
  const entries = timeOffFor(parseIcs(fetchIcs(feedUrl)), name);
  if (holidayFeedUrl) entries.push(...usHolidays(parseIcs(fetchIcs(holidayFeedUrl))));

  // Entries past the lookahead are skipped, since listOutOfOffice cannot see
  // them and they would be added again on every run.
  const horizon = Utilities.formatDate(new Date(Date.now() + (LOOKAHEAD_DAYS - 1) * 86400000), tz, 'yyyy-MM-dd');
  const wanted = new Map();
  for (const entry of entries) {
    if (entry.end <= today || entry.start >= horizon) continue;
    const summary = entry.label + ' ' + SYNC_TAG;
    wanted.set(entry.start + '|' + entry.end + '|' + summary, { ...entry, summary });
  }

  const existing = new Map();
  for (const event of listOutOfOffice(LOOKAHEAD_DAYS)) {
    if (!(event.summary || '').endsWith(SYNC_TAG)) continue;
    const start = Utilities.formatDate(new Date(event.start.dateTime), tz, 'yyyy-MM-dd');
    const end = Utilities.formatDate(new Date(event.end.dateTime), tz, 'yyyy-MM-dd');
    // Past events are left alone, so finished time off stays on the calendar.
    if (end <= today) continue;
    const key = start + '|' + end + '|' + event.summary;
    if (existing.has(key)) {
      Calendar.Events.remove('primary', event.id, { sendUpdates: 'none' });
      console.log('Removed duplicate ' + key);
      continue;
    }
    existing.set(key, event);
  }

  for (const [key, event] of existing) {
    if (wanted.has(key)) continue;
    Calendar.Events.remove('primary', event.id, { sendUpdates: 'none' });
    console.log('Removed ' + key);
  }
  for (const [key, entry] of wanted) {
    if (existing.has(key)) continue;
    createOutOfOffice(entry.summary, entry.start + 'T00:00:00', entry.end + 'T00:00:00', tz);
    console.log('Added ' + key);
  }
}

function fetchIcs(url) {
  const response = UrlFetchApp.fetch(url, { muteHttpExceptions: true });
  // A failed fetch MUST NOT look like "no time off", or every event would be deleted.
  if (response.getResponseCode() !== 200) {
    throw new Error('BambooHR feed returned HTTP ' + response.getResponseCode());
  }
  const ics = response.getContentText();
  if (ics.indexOf('BEGIN:VCALENDAR') === -1) throw new Error('BambooHR feed is not an iCal file');
  return ics;
}

// Returns {uid, start, end, summary} for each VEVENT; dates are YYYY-MM-DD and
// end is exclusive, as in the feed.
function parseIcs(ics) {
  const lines = ics.replace(/\r?\n[ \t]/g, '').split(/\r?\n/);
  const events = [];
  let current = null;
  for (const line of lines) {
    if (line === 'BEGIN:VEVENT') {
      current = {};
      continue;
    }
    if (line === 'END:VEVENT') {
      // RFC 5545: a date-only DTSTART with no DTEND lasts one day.
      if (current && current.start && !current.end) current.end = nextDay(current.start);
      if (current && current.start && current.summary) events.push(current);
      current = null;
      continue;
    }
    if (!current) continue;
    const colon = line.indexOf(':');
    if (colon === -1) continue;
    const key = line.slice(0, colon).split(';')[0];
    const value = line.slice(colon + 1);
    if (key === 'UID') current.uid = value;
    if (key === 'DTSTART') current.start = icsDate(value);
    if (key === 'DTEND') current.end = icsDate(value);
    if (key === 'SUMMARY') current.summary = value.replace(/\\([,;\\])/g, '$1').replace(/\\n/gi, ' ');
  }
  return events;
}

function nextDay(date) {
  const d = new Date(date + 'T12:00:00Z');
  d.setUTCDate(d.getUTCDate() + 1);
  return d.toISOString().slice(0, 10);
}

function icsDate(value) {
  const m = /^(\d{4})(\d{2})(\d{2})/.exec(value);
  return m ? m[1] + '-' + m[2] + '-' + m[3] : null;
}

// BambooHR titles entries "Name (Type - N days)"; the label keeps the type.
function timeOffFor(events, name) {
  const prefix = name + ' (';
  return events
    .filter(event => event.summary.startsWith(prefix) && event.summary.endsWith(')'))
    .map(event => ({
      ...event,
      label: event.summary.slice(prefix.length, -1).replace(/\s*-\s*[\d.]+\s+days?$/i, '') || 'Time off',
    }));
}

// Keeps US holidays, labelled by name, and drops any that another kept holiday
// already covers, such as a "Christmas Day" inside "Christmas".
function usHolidays(events) {
  const kept = events
    .filter(event => /^Company Holiday - /i.test(event.summary))
    .map(event => ({
      ...event,
      label: event.summary.replace(/^Company Holiday - /i, '').replace(/\s*\(.*\)\s*$/, ''),
    }))
    .filter(event => US_HOLIDAYS.some(([name, from, to]) =>
      name.test(event.label) && event.start.slice(5) >= from && event.start.slice(5) <= to));
  return kept.filter((event, i) => !kept.some((other, j) => j !== i &&
    other.start <= event.start && other.end >= event.end &&
    (other.start < event.start || other.end > event.end || j < i)));
}

// Lists out-of-office events from a day ago, so no time zone offset can hide
// today's events, through the lookahead.
function listOutOfOffice(days) {
  const from = new Date(Date.now() - 86400000);
  const to = new Date(Date.now() + days * 86400000);
  const items = [];
  let pageToken;
  do {
    const page = Calendar.Events.list('primary', {
      timeMin: from.toISOString(),
      timeMax: to.toISOString(),
      eventTypes: ['outOfOffice'],
      singleEvents: true,
      maxResults: 250,
      pageToken,
    });
    items.push(...(page.items || []));
    pageToken = page.nextPageToken;
  } while (pageToken);
  return items;
}

function createOutOfOffice(summary, start, end, tz) {
  return Calendar.Events.insert({
    summary,
    eventType: 'outOfOffice',
    transparency: 'opaque',
    start: { dateTime: start, timeZone: tz },
    end: { dateTime: end, timeZone: tz },
    outOfOfficeProperties: { autoDeclineMode: 'declineOnlyNewConflictingInvitations' },
  }, 'primary', { sendUpdates: 'none' });
}

function installTrigger() {
  for (const trigger of ScriptApp.getProjectTriggers()) {
    if (trigger.getHandlerFunction() === 'syncTimeOff') ScriptApp.deleteTrigger(trigger);
  }
  ScriptApp.newTrigger('syncTimeOff').timeBased().everyHours(1).create();
  syncTimeOff();
}
