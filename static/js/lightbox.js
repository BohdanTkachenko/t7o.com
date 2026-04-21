document.querySelectorAll("article img[srcset]").forEach((i) => {
  if (i.closest("a")) return;
  i.style.cursor = "pointer";
  i.onclick = () => {
    let d = document.createElement("div"),
      s = i.srcset.split(",").pop().trim().split(" ")[0];
    d.className = "lb";
    d.innerHTML = '<img src="' + s + '">';
    document.body.style.overflow = "hidden";
    d.onclick = () => {
      d.remove();
      document.body.style.overflow = "";
    };
    document.body.appendChild(d);
  };
});
