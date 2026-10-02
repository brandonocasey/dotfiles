(() => {
  if (window.parent === window) return;
  let enabled = false;
  let outlined = null;
  let previous = '';
  let priority = '';
  function clearOutline() {
    if (!outlined) return;
    outlined.style.setProperty('outline', previous, priority);
    outlined = null;
  }
  window.addEventListener('message', event => {
    if (event.source !== window.parent || event.data?.type !== 'preview:pin-mode') return;
    enabled = event.data.enabled === true;
    if (!enabled) clearOutline();
  });
  document.addEventListener('pointerover', event => {
    if (!enabled || !(event.target instanceof Element)) return;
    clearOutline();
    outlined = event.target;
    previous = outlined.style.getPropertyValue('outline');
    priority = outlined.style.getPropertyPriority('outline');
    outlined.style.setProperty('outline', '3px solid #e87d22', 'important');
  }, true);
  function selectorFor(element) {
    const parts = [];
    for (let node = element; node && node.nodeType === 1; node = node.parentElement) {
      if (node.id && document.querySelectorAll('#' + CSS.escape(node.id)).length === 1) {
        const selector = ['#' + CSS.escape(node.id), ...parts].join(' > ');
        if (selector.length <= 1000) return { selector };
      }
      const siblings = node.parentElement ? [...node.parentElement.children].filter(child => child.localName === node.localName) : [node];
      parts.unshift(CSS.escape(node.localName) + ':nth-of-type(' + (siblings.indexOf(node) + 1) + ')');
      const selector = parts.join(' > ');
      if (selector.length > 1000) { parts.shift(); break; }
      if (document.querySelectorAll(selector).length === 1) return { selector };
    }
    const selector = parts.join(' > ') || '*';
    return { selector, matchIndex: [...document.querySelectorAll(selector)].indexOf(element) };
  }
  document.addEventListener('click', event => {
    if (!enabled || !(event.target instanceof Element)) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    const element = event.target;
    clearOutline();
    window.parent.postMessage({ type: 'preview:annotation', anchor: {
      kind: 'element', ...selectorFor(element),
      text: (element.innerText || element.getAttribute('alt') || element.localName).trim().slice(0, 500),
    } }, '*');
    enabled = false;
  }, true);
})();
