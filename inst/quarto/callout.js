function expandAllCallouts() {
  document.querySelectorAll(".callout-collapse.collapse").forEach(el => {
    if (!el.classList.contains("show")) {
      new bootstrap.Collapse(el, { show: true });
    }
  });
}

function collapseAllCallouts() {
  document.querySelectorAll(".callout-collapse.collapse").forEach(el => {
    if (el.classList.contains("show")) {
      new bootstrap.Collapse(el, { hide: true });
    }
  });
}