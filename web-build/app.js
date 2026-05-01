(function () {
  'use strict';

  var RESOURCE = 'hbs-tow';
  var root = document.getElementById('app');

  var state = {
    open: false,
    screen: 'home',
    stats: null,
    active: null,
    calls: null,
    history: null,
    loading: false,
  };

  function nuiFetch(name, data) {
    return fetch('https://' + RESOURCE + '/' + name, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data || {}),
    })
      .then(function (r) { return r.json(); })
      .catch(function () { return null; });
  }

  function escapeHtml(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }

  function fmtMoney(n) { return '$' + (n || 0).toLocaleString(); }

  function levelBar(value, max) {
    var pct = max > 0 ? Math.min(100, (value / max) * 100) : 0;
    return '<div class="bar"><div class="bar-fill" style="width:' + pct + '%"></div></div>';
  }

  var NAV = [
    { key: 'home', label: 'Home' },
    { key: 'calls', label: 'Calls' },
    { key: 'active', label: 'Active' },
    { key: 'history', label: 'History' },
    { key: 'stats', label: 'Stats' },
  ];

  function renderSidebar() {
    var navHtml = NAV.map(function (it) {
      return '<button class="nav-item ' + (state.screen === it.key ? 'active' : '') +
             '" data-screen="' + it.key + '">' + it.label + '</button>';
    }).join('');
    return (
      '<div class="sidebar">' +
        '<div class="sidebar-header"><h1>HBS TOW</h1><p>Dispatch</p></div>' +
        '<nav>' + navHtml + '</nav>' +
        '<button class="close-btn" data-action="close">Close</button>' +
      '</div>'
    );
  }

  function renderHome() {
    var s = state.stats || {};
    var a = state.active;
    var activeHtml = a
      ? '<div class="active-banner">' +
          '<div class="label-tiny" style="color:var(--primary)">Active Job</div>' +
          '<div style="font-size:20px;font-weight:600;margin-top:4px">' + escapeHtml(a.label) + '</div>' +
          '<div class="subtitle">' + escapeHtml(a.district || '') + '</div>' +
        '</div>'
      : '<button class="btn-primary section" data-action="goCalls" style="margin-top:16px">Find Available Calls</button>';

    return (
      '<div>' +
        '<h1>Dispatch</h1>' +
        '<p class="subtitle">Tow Truck Operator</p>' +
        '<div class="section card card-lg">' +
          '<div class="row">' +
            '<div>' +
              '<div class="label-tiny">Towing Level</div>' +
              '<div class="metric-value">' + (s.level || 0) + '</div>' +
            '</div>' +
            '<div style="text-align:right">' +
              '<div class="label-tiny">XP</div>' +
              '<div style="font-size:14px">' + (s.xpIntoLevel || 0) + ' / ' + (s.xpForNext || 0) + '</div>' +
            '</div>' +
          '</div>' +
          levelBar(s.xpIntoLevel || 0, s.xpForNext || 100) +
        '</div>' +
        '<div class="section grid-2">' +
          '<div class="card"><div class="label-tiny">Total Jobs</div><div class="metric-value">' + (s.jobs || 0) + '</div></div>' +
          '<div class="card"><div class="label-tiny">Total Earned</div><div class="metric-value primary">' + fmtMoney(s.earned) + '</div></div>' +
        '</div>' +
        activeHtml +
      '</div>'
    );
  }

  function renderCalls() {
    var calls = state.calls || [];
    var cards = calls.map(function (c) {
      return (
        '<div class="call-card ' + (c.locked ? 'locked' : '') + '">' +
          '<div class="call-header">' +
            '<div>' +
              '<div class="call-type">' + escapeHtml(c.label) + '</div>' +
              '<div class="call-model">' + escapeHtml(c.model) + '</div>' +
              '<div class="call-district">' + escapeHtml(c.district || '') + '</div>' +
            '</div>' +
            '<div class="call-pay">' +
              '<div class="amount">' + fmtMoney(c.basePay) + '</div>' +
              '<div class="xp">+' + c.xp + ' XP</div>' +
            '</div>' +
          '</div>' +
          '<button class="btn-primary" style="margin-top:16px" data-action="accept" data-id="' + c.id + '"' +
            (c.locked ? ' disabled' : '') + '>' +
            (c.locked ? 'Requires Towing lvl ' + c.minLevel : 'Accept') +
          '</button>' +
        '</div>'
      );
    }).join('');

    var listHtml = '';
    if (state.loading) listHtml = '<div class="empty">Loading...</div>';
    else if (calls.length === 0) listHtml = '<div class="empty">No calls available right now.</div>';
    else listHtml = '<div class="section grid-2">' + cards + '</div>';

    return (
      '<div>' +
        '<div class="flex-between">' +
          '<h1>Available Calls</h1>' +
          '<button class="btn-secondary" data-action="refreshCalls">Refresh</button>' +
        '</div>' +
        listHtml +
      '</div>'
    );
  }

  function renderActive() {
    var m = state.active;
    if (!m) {
      return '<div><h1>Active Job</h1><div class="empty">No active job.</div></div>';
    }
    return (
      '<div>' +
        '<h1>Active Job</h1>' +
        '<div class="section card card-lg">' +
          '<div class="label-tiny" style="color:var(--primary)">' + escapeHtml(m.label) + '</div>' +
          '<div style="font-size:22px;font-weight:600;margin-top:8px">' + escapeHtml(m.district || '') + '</div>' +
          '<div class="subtitle" style="margin-top:4px">Base pay: ' + fmtMoney(m.basePay) + '</div>' +
        '</div>' +
        '<button class="btn-primary danger section" data-action="abandon" style="margin-top:24px">Abandon Job</button>' +
      '</div>'
    );
  }

  function renderHistory() {
    var items = state.history || [];
    if (items.length === 0) return '<div><h1>Recent Jobs</h1><div class="empty">No completed jobs yet.</div></div>';
    var rows = items.map(function (it) {
      var time = new Date(it.ts * 1000).toLocaleTimeString();
      return (
        '<div class="history-row">' +
          '<div>' +
            '<div style="font-weight:500">' + escapeHtml(it.label) + '</div>' +
            '<div class="label-tiny" style="text-transform:none">' + time + '</div>' +
          '</div>' +
          '<div class="pay">+' + fmtMoney(it.pay) + '</div>' +
        '</div>'
      );
    }).join('');
    return '<div><h1>Recent Jobs</h1><div class="section">' + rows + '</div></div>';
  }

  function renderStats() {
    var s = state.stats || {};
    return (
      '<div>' +
        '<h1>Statistics</h1>' +
        '<div class="section card card-lg">' +
          '<div class="label-tiny">Towing</div>' +
          '<div class="row" style="margin:8px 0 12px">' +
            '<div class="metric-value">Level ' + (s.level || 0) + '</div>' +
            '<div class="subtitle">' + (s.xpIntoLevel || 0) + ' / ' + (s.xpForNext || 0) + ' XP</div>' +
          '</div>' +
          levelBar(s.xpIntoLevel || 0, s.xpForNext || 100) +
        '</div>' +
        '<div class="section grid-2">' +
          '<div class="card"><div class="label-tiny">Jobs Completed</div><div class="metric-value">' + (s.jobs || 0) + '</div></div>' +
          '<div class="card"><div class="label-tiny">Total Earned</div><div class="metric-value primary">' + fmtMoney(s.earned) + '</div></div>' +
        '</div>' +
      '</div>'
    );
  }

  function renderContent() {
    switch (state.screen) {
      case 'home':    return renderHome();
      case 'calls':   return renderCalls();
      case 'active':  return renderActive();
      case 'history': return renderHistory();
      case 'stats':   return renderStats();
      default:        return '';
    }
  }

  function bind() {
    root.querySelectorAll('[data-screen]').forEach(function (b) {
      b.addEventListener('click', function () { setScreen(b.getAttribute('data-screen')); });
    });
    root.querySelectorAll('[data-action]').forEach(function (b) {
      var action = b.getAttribute('data-action');
      if (action === 'close')        b.addEventListener('click', closeTablet);
      else if (action === 'goCalls') b.addEventListener('click', function () { setScreen('calls'); });
      else if (action === 'refreshCalls') b.addEventListener('click', loadCalls);
      else if (action === 'accept') b.addEventListener('click', function () {
        acceptCall(parseInt(b.getAttribute('data-id'), 10));
      });
      else if (action === 'abandon') b.addEventListener('click', abandon);
    });
  }

  function render() {
    if (!state.open) {
      root.classList.remove('open');
      root.innerHTML = '';
      return;
    }
    root.classList.add('open');
    root.innerHTML =
      '<div class="tablet">' + renderSidebar() +
      '<div class="content">' + renderContent() + '</div></div>';
    bind();
  }

  function setScreen(s) {
    state.screen = s;
    render();
    if (s === 'calls' && state.calls === null) loadCalls();
    if (s === 'history') loadHistory();
  }

  function loadAll() {
    return Promise.all([nuiFetch('getStats'), nuiFetch('getActive')]).then(function (res) {
      state.stats = res[0];
      state.active = res[1];
    });
  }

  function loadCalls() {
    state.loading = true;
    render();
    return nuiFetch('getCalls').then(function (data) {
      state.calls = data || [];
      state.loading = false;
      render();
    });
  }

  function loadHistory() {
    return nuiFetch('getHistory').then(function (data) {
      state.history = data || [];
      render();
    });
  }

  function acceptCall(id) {
    nuiFetch('acceptCall', { id: id }).then(function (res) {
      if (res && res.ok) closeTablet();
    });
  }

  function abandon() {
    nuiFetch('abandon').then(function () {
      state.active = null;
      state.screen = 'home';
      render();
    });
  }

  function closeTablet() {
    state.open = false;
    render();
    nuiFetch('close');
  }

  window.addEventListener('message', function (e) {
    var msg = e.data;
    if (!msg) return;
    if (msg.action === 'open') {
      state.open = true;
      state.screen = 'home';
      state.calls = null;
      state.history = null;
      loadAll().then(render);
      render();
    } else if (msg.action === 'close') {
      state.open = false;
      render();
    } else if (msg.action === 'updateActive') {
      state.active = msg.payload;
      render();
    }
  });

  window.addEventListener('keydown', function (e) {
    if (state.open && e.key === 'Escape') closeTablet();
  });

  render();
})();
