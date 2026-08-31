import { Turbo } from "@hotwired/turbo-rails"

Turbo.config.forms.confirm = (message, formElement, submitter) => {
  const dialog = document.getElementById("turbo_confirm_dialog")
  dialog.querySelector("[data-turbo-confirm-message]").textContent = message
  dialog.showModal()

  return new Promise((resolve) => {
    const acceptBtn = dialog.querySelector("[data-turbo-confirm-accept]")
    const cancelBtn = dialog.querySelector("[data-turbo-confirm-cancel]")

    const cleanup = (result) => {
      dialog.close()
      acceptBtn.removeEventListener("click", onAccept)
      cancelBtn.removeEventListener("click", onCancel)
      resolve(result)
    }
    const onAccept = () => cleanup(true)
    const onCancel = () => cleanup(false)

    acceptBtn.addEventListener("click", onAccept, { once: true })
    cancelBtn.addEventListener("click", onCancel, { once: true })
  })
}
