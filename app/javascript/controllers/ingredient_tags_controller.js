import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["count", "form", "input", "submit", "tags"]
  static values = { initialTags: Array }

  connect() {
    this.tags = []
    this.initialTagsValue.forEach((name) => this.addTag(name))
    this.refresh()
  }

  handleKeydown(event) {
    if (["Enter", "Tab", ","].includes(event.key)) {
      const value = this.inputTarget.value.trim()

      if (event.key === "Enter" && value === "") {
        if (this.selectedCount() > 0) {
          event.preventDefault()
          this.formTarget.requestSubmit()
        }

        return
      }

      if (value !== "") {
        event.preventDefault()
        this.addTag(value)
        this.inputTarget.value = ""
        this.refresh()
      }
    }
  }

  handleBlur() {
    const value = this.inputTarget.value.trim()
    if (value === "") return

    this.addTag(value)
    this.inputTarget.value = ""
    this.refresh()
  }

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

    const index = Number(event.currentTarget.dataset.index)
    this.tags.splice(index, 1)
    this.refresh()
  }

  clearAll() {
    this.tags = []
    this.inputTarget.value = ""
    this.refresh()
    this.inputTarget.focus()
  }

  addTag(name) {
    const trimmed = name.trim()
    const normalized = this.normalize(trimmed)
    if (normalized.length < 3) return

    const existingTag = this.tags.find((tag) => tag.normalized === normalized)
    if (existingTag) {
      existingTag.selected = true
      return
    }

    this.tags.push({
      name: trimmed,
      normalized,
      selected: true
    })
  }

  normalize(value) {
    return value.trim().replace(/\s+/g, " ").toLowerCase()
  }

  selectedCount() {
    return this.tags.filter((tag) => tag.selected).length
  }

  refresh() {
    this.renderTags()
    this.countTarget.textContent = this.selectedCount()
    this.submitTarget.disabled = this.selectedCount() === 0
  }

  renderTags() {
    this.tagsTarget.innerHTML = ""

    this.tags.forEach((tag, index) => {
      const chip = document.createElement("div")
      chip.dataset.index = index
      chip.dataset.action = "click->ingredient-tags#toggle"
      chip.className = tag.selected ? "chip is-selected" : "chip"

      const label = document.createElement("span")
      label.textContent = tag.name
      chip.appendChild(label)

      const remove = document.createElement("button")
      remove.type = "button"
      remove.dataset.index = index
      remove.dataset.action = "click->ingredient-tags#remove"
      remove.className = "chip-remove"
      remove.setAttribute("aria-label", `Remove ${tag.name}`)
      remove.textContent = "x"
      chip.appendChild(remove)

      if (tag.selected) {
        const input = document.createElement("input")
        input.type = "hidden"
        input.name = "ingredients[]"
        input.value = tag.name
        chip.appendChild(input)
      }

      this.tagsTarget.appendChild(chip)
    })
  }
}
