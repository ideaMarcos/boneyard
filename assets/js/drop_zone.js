export const DropZone = {
  mounted() {
    const el = this.el;

    // Desktop drop events
    el.addEventListener("dragover", e => {
      e.preventDefault();
      e.dataTransfer.dropEffect = "move";
      el.classList.add("drag-over");
    });

    el.addEventListener("dragleave", () => {
      el.classList.remove("drag-over");
    });

    el.addEventListener("drop", e => {
      e.preventDefault();
      el.classList.remove("drag-over");

      const tileId = e.dataTransfer.getData("text/plain");
      if (tileId) {
        this.pushEvent("play_tile", {
          id: tileId,
          side: el.dataset.side
        });
      }
    });

    // Mobile touch events
    el.addEventListener("touchend", e => {
      const draggingTile = document.querySelector(".dragging");
      if (draggingTile) {
        e.preventDefault();
        const tileId = draggingTile.dataset.tileId;

        this.pushEvent("play_tile", {
          id: tileId,
          side: el.dataset.side
        });

        draggingTile.classList.remove("dragging");
      }
    });
  }
}; 