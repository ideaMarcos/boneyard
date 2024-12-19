export const DraggableTile = {
  mounted() {
    const el = this.el;

    // Desktop drag and drop
    el.addEventListener("dragstart", e => {
      el.classList.add("dragging");
      e.dataTransfer.effectAllowed = "move";
      e.dataTransfer.setData("text/plain", el.dataset.tileId);
    });

    el.addEventListener("dragend", () => {
      el.classList.remove("dragging");
    });

    // Mobile touch events
    let touchTimeout;
    let startX;
    let startY;

    el.addEventListener("touchstart", e => {
      const touch = e.touches[0];
      startX = touch.clientX;
      startY = touch.clientY;

      touchTimeout = setTimeout(() => {
        el.classList.add("dragging");
      }, 200);
    }, { passive: true });

    el.addEventListener("touchmove", e => {
      const touch = e.touches[0];
      const deltaX = Math.abs(touch.clientX - startX);
      const deltaY = Math.abs(touch.clientY - startY);

      if (deltaX > 10 || deltaY > 10) {
        clearTimeout(touchTimeout);
      }
    }, { passive: true });

    el.addEventListener("touchend", () => {
      clearTimeout(touchTimeout);
      el.classList.remove("dragging");
    });
  }
}; 