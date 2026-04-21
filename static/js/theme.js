(function () {
  var m = matchMedia("(prefers-color-scheme:dark)"),
    t = localStorage.theme || (m.matches ? "dark" : "light"),
    h = document.documentElement,
    c = document.getElementById("tc");
  h.className = t;
  function u() {
    c.content = getComputedStyle(h).getPropertyValue("--tc");
  }
  u();
  window.T = function () {
    t = t === "dark" ? "light" : "dark";
    localStorage.theme = t;
    h.className = t;
    u();
  };
})();
