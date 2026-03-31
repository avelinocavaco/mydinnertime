import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["chips", "count", "form", "input", "submit"]
  static values = { initialTags: Array }

  connect() {
    this.tags = this.initialTagsValue.map((tag) => this.buildTag(tag)).filter(Boolean)
    this.refresh()
  }

  handleKeydown(event) {
    if (event.key === "Tab" || event.key === ",") {
      if (this.commitInput()) event.preventDefault()
      return
    }

    if (event.key === "Enter") {
      event.preventDefault()
      this.commitInput()
      if (this.selectedCount() > 0) this.formTarget.requestSubmit()
    }
  }

  handleBlur() { this.commitInput() }
  focusInput() { this.inputTarget.focus() }

  toggle(event) {
    event.preventDefault()
    const index = Number(event.currentTarget.dataset.index)
    const tag = this.tags[index]
    if (!tag) return
    tag.selected = !tag.selected
    this.refresh()
  }

  remove(event) {
    event.preventDefault()
    event.stopPropagation()
    this.tags.splice(Number(event.currentTarget.dataset.index), 1)
    this.refresh()
  }

  clearAll() {
    this.tags = []
    this.inputTarget.value = ""
    this.refresh()
    this.inputTarget.focus()
  }

  buildTag(tagData) {
    const name = typeof tagData === "string" ? tagData : tagData.name
    const selected = typeof tagData === "string" ? true : tagData.selected !== false
    const trimmed = name.trim()
    const normalized = this.normalize(trimmed)
    return normalized.length < 3 ? null : { name: trimmed, normalized, selected }
  }

  addTag(tagData) {
    const nextTag = this.buildTag(tagData)
    if (!nextTag) return false

    const { normalized, selected } = nextTag
    const existingTag = this.tags.find((tag) => tag.normalized === normalized)
    if (existingTag) {
      existingTag.selected = selected
      return true
    }
    this.tags.push(nextTag)
    return true
  }

  commitInput() {
    const value = this.inputTarget.value.trim()
    if (value === "") return false
    const added = this.addTag(value)
    this.inputTarget.value = ""
    this.refresh()
    return added
  }

  normalize(value) { return value.trim().replace(/\s+/g, " ").toLowerCase() }
  selectedCount() { return this.tags.filter((tag) => tag.selected).length }

  refresh() {
    const selectedCount = this.selectedCount()
    this.countTarget.textContent = selectedCount
    this.submitTarget.disabled = selectedCount === 0
    this.inputTarget.placeholder = this.tags.length === 0 ? "e.g. tomato, garlic, chicken" : ""
    this.renderTags()
  }

  renderTags() {
    this.chipsTarget.innerHTML = this.tags.map((tag, index) => `
      <div class="chip${tag.selected ? " is-selected" : ""}" data-index="${index}" data-action="click->ingredient-tags#toggle">
        <span>${this.escape(tag.name)}</span>
        <button type="button" class="chip-remove" data-index="${index}" data-action="click->ingredient-tags#remove" aria-label="Remove ${this.escape(tag.name)}">x</button>
        <input type="hidden" name="ingredients[]" value="${this.escape(tag.name)}">
        <input type="hidden" name="ingredient_selected[]" value="${tag.selected}">
      </div>
    `).join("")
  }

  escape(value) {
    return value.replaceAll("&", "&amp;").replaceAll('"', "&quot;").replaceAll("<", "&lt;").replaceAll(">", "&gt;")
  }
}
