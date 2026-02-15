# FASE 4 - Melhorias e Novas Funcionalidades

> **Prioridade:** BAIXA (nice to have)
> **Pre-requisito:** Fases 1, 2 e 3 concluidas
> **Impacto:** Eleva a aplicacao de funcional para profissional

---

## 1. Funcionalidades Avancadas

### 1.1 Exportacao de Dados (CSV/PDF)

**Objetivo:** Permitir que o usuario exporte suas transacoes em CSV e PDF.

**Implementacao:**

**Gem necessaria:**
```ruby
gem 'prawn'       # Geracao de PDF
gem 'prawn-table'  # Tabelas em PDF
```

**Controller:** Adicionar ao `FinancialEntriesController`
```ruby
def index
  # ... codigo existente de filtros ...

  respond_to do |format|
    format.html
    format.csv { send_data generate_csv(@financial_entries), filename: "transacoes-#{Date.current}.csv" }
    format.pdf { send_data generate_pdf(@financial_entries), filename: "transacoes-#{Date.current}.pdf" }
  end
end

private

def generate_csv(entries)
  CSV.generate(headers: true, col_sep: ';') do |csv|
    csv << ['Data', 'Descricao', 'Categoria', 'Tipo', 'Valor']
    entries.each do |entry|
      csv << [
        entry.date.strftime('%d/%m/%Y'),
        entry.description,
        entry.category&.name,
        entry.income? ? 'Receita' : 'Despesa',
        entry.amount
      ]
    end
  end
end
```

**Botoes na view:**
```erb
<div class="export-actions">
  <%= link_to "Exportar CSV", financial_entries_path(format: :csv, **request.query_parameters),
      class: "btn btn-outline btn-sm" %>
  <%= link_to "Exportar PDF", financial_entries_path(format: :pdf, **request.query_parameters),
      class: "btn btn-outline btn-sm" %>
</div>
```

---

### 1.2 Busca de Transacoes

**Objetivo:** Campo de pesquisa para encontrar transacoes por descricao.

**Controller:** Adicionar filtro no `FinancialEntriesController#index`
```ruby
if params[:search].present?
  @financial_entries = @financial_entries
    .where("description ILIKE ?", "%#{params[:search]}%")
end
```

**View:** Campo de busca no topo da lista
```erb
<%= form_tag financial_entries_path, method: :get, class: "search-form" do %>
  <%= text_field_tag :search, params[:search],
      placeholder: "Buscar transacao...",
      class: "search-input" %>
  <%= submit_tag "Buscar", class: "btn btn-sm btn-primary" %>
<% end %>
```

---

### 1.3 Alertas de Orcamento

**Objetivo:** Notificar o usuario quando os gastos se aproximam ou ultrapassam o limite do orcamento.

**Model:** Adicionar metodos ao `MonthlyBudget`
```ruby
def alert_level
  pct = percentage_used
  case pct
  when 0..70   then :normal
  when 71..90  then :warning
  when 91..100 then :danger
  else              :exceeded
  end
end

def alert_message
  case alert_level
  when :warning  then "Voce ja usou #{percentage_used}% do orcamento"
  when :danger   then "Atencao! Voce esta em #{percentage_used}% do orcamento"
  when :exceeded then "Orcamento ultrapassado em R$ #{'%.2f' % remaining.abs}"
  end
end
```

**Dashboard:** Exibir alerta no topo
```erb
<% budget = current_user.monthly_budgets.find_by(month: Date.current.beginning_of_month) %>
<% if budget && budget.alert_level != :normal %>
  <div class="budget-alert <%= budget.alert_level %>">
    <%= budget.alert_message %>
  </div>
<% end %>
```

---

### 1.4 Paginacao

**Objetivo:** Paginar a lista de transacoes para melhor performance com muitos registros.

**Gem:**
```ruby
gem 'kaminari'
```

**Controller:**
```ruby
@financial_entries = @financial_entries.page(params[:page]).per(20)
```

**View:**
```erb
<%= paginate @financial_entries %>
```

---

### 1.5 Graficos no Dashboard

**Objetivo:** Adicionar mini-graficos ao dashboard usando chartkick (ja instalado).

**Dashboard Controller - dados extras:**
```ruby
# Grafico dos ultimos 7 dias
@daily_expenses = current_user.financial_entries
  .expenses
  .where(date: 7.days.ago..Date.current)
  .group(:date)
  .sum(:amount)

# Top categorias do mes
@top_categories = current_user.financial_entries
  .expenses
  .this_month
  .joins(:category)
  .group('categories.name')
  .order('sum_amount DESC')
  .limit(5)
  .sum(:amount)
```

**Dashboard View:**
```erb
<div class="chart-section mobile-card">
  <h3>Gastos - Ultimos 7 dias</h3>
  <%= line_chart @daily_expenses, prefix: "R$ ", colors: ["#dc3545"] %>
</div>

<div class="chart-section mobile-card">
  <h3>Top Categorias do Mes</h3>
  <%= pie_chart @top_categories, prefix: "R$ " %>
</div>
```

---

### 1.6 Transacoes Recorrentes

**Objetivo:** Permitir que transacoes fixas (aluguel, salario) sejam geradas automaticamente todo mes.

**Migration:**
```ruby
class AddRecurringToFinancialEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :financial_entries, :recurring, :boolean, default: false
    add_column :financial_entries, :recurring_day, :integer  # dia do mes (1-31)
  end
end
```

**Model:**
```ruby
scope :recurring, -> { where(recurring: true) }

def self.generate_recurring_for_month(user, date = Date.current)
  user.financial_entries.recurring.find_each do |entry|
    target_date = date.beginning_of_month + (entry.recurring_day - 1).days
    unless user.financial_entries.exists?(
      description: entry.description,
      date: target_date.beginning_of_month..target_date.end_of_month,
      recurring: false
    )
      user.financial_entries.create!(
        description: entry.description,
        amount: entry.amount,
        entry_type: entry.entry_type,
        category: entry.category,
        date: target_date,
        recurring: false
      )
    end
  end
end
```

---

### 1.7 Perfil do Usuario Customizado

**Objetivo:** Substituir o formulario padrao do Devise por um perfil completo.

**Controller:** `app/controllers/profiles_controller.rb`
```ruby
class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @stats = {
      total_entries: current_user.financial_entries.count,
      total_income: current_user.financial_entries.incomes.sum(:amount),
      total_expenses: current_user.financial_entries.expenses.sum(:amount),
      categories_count: current_user.categories.count,
      member_since: current_user.created_at
    }
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(profile_params)
      redirect_to profile_path, notice: 'Perfil atualizado.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :monthly_income, :currency, :timezone, :avatar_url)
  end
end
```

**Routes:**
```ruby
resource :profile, only: [:show, :edit, :update]
```

---

## 2. Melhorias de UX/UI

### 2.1 Feedback Visual

**Notificacoes toast** em vez de flash messages basicas:
```erb
<!-- app/views/layouts/application.html.erb -->
<% if notice || alert %>
  <div class="toast-container">
    <% if notice %>
      <div class="toast success" data-auto-dismiss="3000">
        <%= notice %>
      </div>
    <% end %>
    <% if alert %>
      <div class="toast danger" data-auto-dismiss="5000">
        <%= alert %>
      </div>
    <% end %>
  </div>
<% end %>
```

### 2.2 Confirmacao de Exclusao

Substituir `confirm` nativo do browser por modal customizado:
```erb
<!-- Ao inves de: -->
data: { turbo_confirm: 'Tem certeza?' }

<!-- Criar partial: -->
<!-- app/views/shared/_confirm_modal.html.erb -->
```

### 2.3 Loading States

Adicionar feedback visual durante carregamento:
```erb
<%= form_with(..., data: { turbo_submits_with: "Salvando..." }) do |f| %>
```

### 2.4 Acessibilidade

Adicionar atributos ARIA nas views:
```erb
<!-- Navegacao -->
<nav class="bottom-nav" role="navigation" aria-label="Menu principal">

<!-- Botoes -->
<%= link_to ..., aria: { label: "Editar transacao #{transaction.description}" } %>

<!-- Icones -->
<span class="nav-icon" aria-hidden="true">🏠</span>
```

---

## 3. Testes

### 3.1 Estrutura de Testes a Criar

**Gem:** Ja tem `debug` configurado, adicionar:
```ruby
group :test do
  gem 'factory_bot_rails'
  gem 'shoulda-matchers'
  gem 'capybara'
  gem 'selenium-webdriver'
end
```

**Testes de Model:**
```
test/models/
  user_test.rb
  financial_entry_test.rb
  category_test.rb
  monthly_budget_test.rb
```

**Testes de Controller:**
```
test/controllers/
  dashboard_controller_test.rb
  financial_entries_controller_test.rb
  categories_controller_test.rb
  monthly_budgets_controller_test.rb
  reports_controller_test.rb
```

**Testes de Integracao:**
```
test/integration/
  user_registration_test.rb
  transaction_flow_test.rb
  budget_management_test.rb
```

### 3.2 Exemplos de Testes Prioritarios

**Model FinancialEntry:**
```ruby
class FinancialEntryTest < ActiveSupport::TestCase
  test "deve exigir descricao" do
    entry = FinancialEntry.new(description: nil)
    assert_not entry.valid?
    assert_includes entry.errors[:description], "can't be blank"
  end

  test "deve exigir amount maior que zero" do
    entry = FinancialEntry.new(amount: -10)
    assert_not entry.valid?
  end

  test "scope this_month retorna apenas transacoes do mes atual" do
    # ...
  end

  test "scope incomes retorna apenas receitas" do
    # ...
  end
end
```

**Controller FinancialEntries:**
```ruby
class FinancialEntriesControllerTest < ActionDispatch::IntegrationTest
  test "usuario nao autenticado e redirecionado" do
    get financial_entries_path
    assert_redirected_to new_user_session_path
  end

  test "usuario nao pode ver transacoes de outro usuario" do
    # ...
  end

  test "filtro por tipo funciona corretamente" do
    # ...
  end
end
```

---

## 4. Melhorias de Infraestrutura

### 4.1 Background Jobs

Para funcionalidades como transacoes recorrentes e alertas:
```ruby
# app/jobs/generate_recurring_entries_job.rb
class GenerateRecurringEntriesJob < ApplicationJob
  queue_as :default

  def perform
    User.find_each do |user|
      FinancialEntry.generate_recurring_for_month(user)
    end
  end
end
```

Configurar no `solid_queue` (ja incluido no Gemfile):
```yaml
# config/recurring.yml
generate_recurring:
  class: GenerateRecurringEntriesJob
  schedule: every day at 1am
```

### 4.2 Cache

Cachear dados do dashboard que nao mudam frequentemente:
```ruby
def index
  @total_income = Rails.cache.fetch("user_#{current_user.id}_income_#{Date.current.month}", expires_in: 10.minutes) do
    current_user.financial_entries.incomes.this_month.sum(:amount)
  end
end
```

### 4.3 I18n

Mover todas as strings hardcoded para arquivos de traducao:
```yaml
# config/locales/pt-BR.yml
pt-BR:
  activerecord:
    models:
      financial_entry: Transacao
      category: Categoria
      monthly_budget: Orcamento Mensal
    attributes:
      financial_entry:
        description: Descricao
        amount: Valor
        date: Data
        entry_type: Tipo
        category: Categoria
  dashboard:
    greeting: "Ola, %{name}!"
    income: Receitas
    expenses: Despesas
    balance: Saldo
```

---

## 5. Checklist de Implementacao

### Funcionalidades
- [ ] Exportacao CSV de transacoes
- [ ] Exportacao PDF de transacoes
- [ ] Campo de busca de transacoes
- [ ] Alertas de orcamento no dashboard
- [ ] Paginacao com kaminari
- [ ] Mini-graficos no dashboard (chartkick)
- [ ] Transacoes recorrentes (model + job)
- [ ] Perfil customizado do usuario

### UX/UI
- [ ] Toast notifications em vez de flash basico
- [ ] Modal de confirmacao customizado
- [ ] Loading states nos formularios
- [ ] Atributos de acessibilidade (ARIA)

### Testes
- [ ] Configurar factory_bot + shoulda-matchers
- [ ] Testes de model (4 models)
- [ ] Testes de controller (5 controllers)
- [ ] Testes de integracao (3 fluxos)

### Infraestrutura
- [ ] Job para transacoes recorrentes
- [ ] Cache no dashboard
- [ ] Internacionalizacao completa (pt-BR)
- [ ] Configurar CI com GitHub Actions

---

## 6. Arquivos a Criar/Modificar

| Arquivo | Acao |
|---|---|
| `Gemfile` | EDITAR - prawn, kaminari, factory_bot, shoulda-matchers |
| `app/controllers/financial_entries_controller.rb` | EDITAR - export, search, pagination |
| `app/controllers/profiles_controller.rb` | CRIAR |
| `app/models/financial_entry.rb` | EDITAR - recurring scopes |
| `app/models/monthly_budget.rb` | EDITAR - alert methods |
| `app/views/financial_entries/index.html.erb` | EDITAR - search, export, pagination |
| `app/views/dashboard/index.html.erb` | EDITAR - charts, budget alert |
| `app/views/profiles/show.html.erb` | CRIAR |
| `app/views/profiles/edit.html.erb` | CRIAR |
| `app/views/shared/_toast.html.erb` | CRIAR |
| `app/views/layouts/application.html.erb` | EDITAR - toast, ARIA |
| `app/jobs/generate_recurring_entries_job.rb` | CRIAR |
| `config/locales/pt-BR.yml` | CRIAR |
| `config/routes.rb` | EDITAR - profile, reports |
| `db/migrate/xxx_add_recurring.rb` | CRIAR |
| `test/models/*.rb` | CRIAR (4 arquivos) |
| `test/controllers/*.rb` | CRIAR (5 arquivos) |
| `test/integration/*.rb` | CRIAR (3 arquivos) |
| `test/factories/*.rb` | CRIAR (4 arquivos) |

---

## 7. Resumo Geral das 4 Fases

| Fase | Foco | Itens | Prioridade |
|---|---|---|---|
| **1 - Seguranca** | Vulnerabilidades criticas | 12 itens | URGENTE |
| **2 - Funcionalidades** | Features core faltantes | 19 itens | ALTA |
| **3 - Qualidade** | Refatoracao MVC e CSS | 22 itens | MEDIA |
| **4 - Melhorias** | Features avancadas e testes | 24 itens | BAIXA |
| **TOTAL** | | **77 itens** | |
