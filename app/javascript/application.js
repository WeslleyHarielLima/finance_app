// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "chartkick"
import "Chart.bundle"

// Toast auto-dismiss
document.addEventListener("turbo:load", () => {
  document.querySelectorAll(".toast[data-auto-dismiss]").forEach((toast) => {
    const delay = parseInt(toast.dataset.autoDismiss, 10) || 3000;
    setTimeout(() => {
      toast.classList.add("fade-out");
      setTimeout(() => toast.remove(), 300);
    }, delay);
  });

  document.querySelectorAll(".toast-close").forEach((btn) => {
    btn.addEventListener("click", () => {
      const toast = btn.closest(".toast");
      toast.classList.add("fade-out");
      setTimeout(() => toast.remove(), 300);
    });
  });

  // Toggle recurring day field
  const recurringCheckbox = document.querySelector("#financial_entry_recurring");
  const recurringDayField = document.querySelector("#recurring-day-field");
  if (recurringCheckbox && recurringDayField) {
    recurringCheckbox.addEventListener("change", () => {
      recurringDayField.style.display = recurringCheckbox.checked ? "block" : "none";
    });
  }
});
