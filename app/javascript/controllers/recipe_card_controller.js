import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["details", "toggle", "toggleLabel"]

  connect() {
    this.expanded = false
    this.sync()
  }

  toggle() {
    this.expanded = !this.expanded
    this.sync()
  }

  sync() {
    this.element.dataset.expanded = this.expanded
    this.detailsTarget.hidden = !this.expanded
    this.toggleTarget.setAttribute("aria-expanded", String(this.expanded))
    this.toggleLabelTarget.textContent = this.expanded ? "Hide details" : "Show details"
  }
}
