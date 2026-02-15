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

  // Credit card charge form: installment calculator
  const ccAmount = document.querySelector("#credit_card_charge_total_amount");
  const ccInstallments = document.querySelector("#credit_card_charge_installments");
  const ccRecurring = document.querySelector("#credit_card_charge_recurring");
  const ccInstallmentsGroup = document.querySelector("#installments-field");
  const ccPreview = document.querySelector(".installment-preview");

  function updateInstallmentPreview() {
    if (!ccAmount || !ccInstallments || !ccPreview) return;

    const amount = parseFloat(ccAmount.value);
    const installments = parseInt(ccInstallments.value);

    if (ccRecurring && ccRecurring.checked) {
      if (amount > 0) {
        ccPreview.style.display = "block";
        ccPreview.textContent = `R$ ${amount.toFixed(2).replace(".", ",")} / mes`;
      } else {
        ccPreview.style.display = "none";
      }
      return;
    }

    if (amount > 0 && installments > 0) {
      const installmentAmount = (amount / installments).toFixed(2).replace(".", ",");
      ccPreview.style.display = "block";
      ccPreview.textContent = `${installments}x de R$ ${installmentAmount}`;
    } else {
      ccPreview.style.display = "none";
    }
  }

  if (ccAmount) {
    ccAmount.addEventListener("input", updateInstallmentPreview);
  }
  if (ccInstallments) {
    ccInstallments.addEventListener("input", updateInstallmentPreview);
  }
  if (ccRecurring && ccInstallmentsGroup) {
    ccRecurring.addEventListener("change", () => {
      if (ccRecurring.checked) {
        ccInstallmentsGroup.style.display = "none";
        ccInstallments.value = 1;
      } else {
        ccInstallmentsGroup.style.display = "block";
      }
      updateInstallmentPreview();
    });
    // Initialize state
    if (ccRecurring.checked) {
      ccInstallmentsGroup.style.display = "none";
    }
  }
  updateInstallmentPreview();
});
