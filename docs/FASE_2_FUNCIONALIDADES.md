# FASE 2 - Funcionalidades Core Faltantes

> **Prioridade:** ALTA
> **Pre-requisito:** Fase 1 concluida
> **Impacto:** Completa as funcionalidades essenciais que a aplicacao promete mas nao entrega

---

## 1. Diagnostico Atual da Arquitetura MVC

### Mapa do que existe vs. o que falta

| Recurso | Model | Controller | Views | Routes | Status |
|---|---|---|---|---|---|
| User (Devise) | OK | OK (Devise) | Parcial | OK | Registro quebrado (sem campo name) |
| FinancialEntry | OK | OK | OK | OK | Funcionando |
| Category | OK | NAO EXISTE | NAO EXISTE | NAO EXISTE | Apenas seeds, sem CRUD |
| MonthlyBudget | OK | NAO EXISTE | NAO EXISTE | NAO EXISTE | Model orfao, sem interface |
| Dashboard | - | OK | OK | OK | Funcionando, sem graficos |
| Relatorios | - | NAO EXISTE | NAO EXISTE | NAO EXISTE | Link placeholder aponta pra # |
| Pages | - | OK (vazio) | OK | OK | Apenas landing page |

---

## 2. Funcionalidades a Implementar

### 2.1 CRUD de Categorias

**Problema:** O model `Category` existe com validacoes corretas, mas nao ha controller nem views. Categorias so podem ser criadas via `seeds.rb` ou console.

**Arquivos a criar:**

**Controller:** `app/controllers/categories_controller.rb`
```ruby
class CategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_category, only: [:edit, :update, :destroy]

  def index
    @categories = current_user.categories.order(:name)
  end

  def new
    @category = current_user.categories.new
  end

  def create
    @category = current_user.categories.new(category_params)
    if @category.save
      redirect_to categories_path, notice: 'Categoria criada com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @category.update(category_params)
      redirect_to categories_path, notice: 'Categoria atualizada.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @category.financial_entries.exists?
      redirect_to categories_path,
        alert: 'Nao e possivel excluir categoria com transacoes vinculadas.'
    else
      @category.destroy
      redirect_to categories_path, notice: 'Categoria excluida.'
    end
  end

  private

  def set_category
    @category = current_user.categories.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :color, :icon)
  end
end
```

**Views a criar:**
- `app/views/categories/index.html.erb` - Lista de categorias com cores e icones
- `app/views/categories/new.html.erb` - Formulario de nova categoria
- `app/views/categories/edit.html.erb` - Formulario de edicao
- `app/views/categories/_form.html.erb` - Partial do formulario

**Routes a adicionar:**
```ruby
resources :categories, except: [:show]
```

---

### 2.2 Gestao de Orcamento Mensal

**Problema:** O model `MonthlyBudget` existe com validacoes, mas nao ha nenhuma interface. O usuario nao consegue definir, visualizar ou alterar seu orcamento.

**Arquivos a criar:**

**Controller:** `app/controllers/monthly_budgets_controller.rb`
```ruby
class MonthlyBudgetsController < ApplicationController
  before_action :authenticate_user!

  def index
    @budgets = current_user.monthly_budgets.order(month: :desc)
    @current_budget = current_user.monthly_budgets
      .find_by(month: Date.current.beginning_of_month)
  end

  def new
    @budget = current_user.monthly_budgets.new(month: Date.current.beginning_of_month)
  end

  def create
    @budget = current_user.monthly_budgets.new(budget_params)
    if @budget.save
      redirect_to monthly_budgets_path, notice: 'Orcamento definido.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @budget = current_user.monthly_budgets.find(params[:id])
  end

  def update
    @budget = current_user.monthly_budgets.find(params[:id])
    if @budget.update(budget_params)
      redirect_to monthly_budgets_path, notice: 'Orcamento atualizado.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def budget_params
    params.require(:monthly_budget).permit(:month, :total_amount)
  end
end
```

**Views a criar:**
- `app/views/monthly_budgets/index.html.erb` - Historico de orcamentos + barra de progresso do mes atual
- `app/views/monthly_budgets/new.html.erb` - Definir orcamento
- `app/views/monthly_budgets/edit.html.erb` - Editar orcamento
- `app/views/monthly_budgets/_form.html.erb` - Partial do formulario

**Routes:**
```ruby
resources :monthly_budgets, except: [:show, :destroy]
```

**Melhoria no model** - Adicionar metodos uteis:
```ruby
class MonthlyBudget < ApplicationRecord
  belongs_to :user

  validates :month, presence: true, uniqueness: { scope: :user_id }
  validates :total_amount, presence: true, numericality: { greater_than: 0 }

  def spent
    user.financial_entries
      .expenses
      .where(date: month.beginning_of_month..month.end_of_month)
      .sum(:amount)
  end

  def remaining
    total_amount - spent
  end

  def percentage_used
    return 0 if total_amount.zero?
    ((spent / total_amount) * 100).round(1)
  end

  def exceeded?
    spent > total_amount
  end
end
```

---

### 2.3 Pagina de Relatorios

**Problema:** O link "Relatorios" na navegacao inferior aponta para `href="#"`. A gem `chartkick` esta no Gemfile mas nunca e usada.

**Arquivo:** `app/views/shared/_bottom_nav.html.erb` (linhas 17-20)
```erb
<!-- ESTADO ATUAL: -->
<a href="#" class="nav-item">
  <span class="nav-icon">📊</span>
  Relatórios
</a>
```

**Arquivos a criar:**

**Controller:** `app/controllers/reports_controller.rb`
```ruby
class ReportsController < ApplicationController
  before_action :authenticate_user!

  def index
    @current_month = Date.current
    @months_range = 6.months.ago.to_date..Date.current

    # Dados para graficos (chartkick)
    @monthly_expenses = current_user.financial_entries
      .expenses
      .where(date: @months_range)
      .group_by_month(:date)
      .sum(:amount)

    @monthly_incomes = current_user.financial_entries
      .incomes
      .where(date: @months_range)
      .group_by_month(:date)
      .sum(:amount)

    # Gastos por categoria (mes atual)
    @expenses_by_category = current_user.financial_entries
      .expenses
      .this_month
      .joins(:category)
      .group('categories.name')
      .sum(:amount)

    # Resumo mensal
    @total_income_month = current_user.financial_entries.incomes.this_month.sum(:amount)
    @total_expense_month = current_user.financial_entries.expenses.this_month.sum(:amount)
  end
end
```

**Gem adicional necessaria:**
```ruby
gem 'groupdate'  # Para group_by_month, group_by_week etc.
```

**View:** `app/views/reports/index.html.erb` - Graficos com chartkick:
- Grafico de linha: Receitas vs Despesas (ultimos 6 meses)
- Grafico de pizza: Gastos por categoria (mes atual)
- Grafico de barras: Comparativo mensal

**Routes:**
```ruby
resources :reports, only: [:index]
```

**Corrigir navegacao:**
```erb
<!-- app/views/shared/_bottom_nav.html.erb -->
<%= link_to reports_path, class: "nav-item #{'active' if current_page?(reports_path)}" do %>
  <span class="nav-icon">📊</span>
  Relatorios
<% end %>
```

---

### 2.4 Views do Devise - Internacionalizacao e Estilizacao

**Problema:** As views do Devise estao misturadas entre portugues e ingles, e os formularios de registro/edicao usam o template padrao sem estilizacao.

**Arquivos afetados:**

| Arquivo | Problema |
|---|---|
| `devise/registrations/new.html.erb` | Em ingles ("Sign up"), sem campo name, sem estilo |
| `devise/registrations/edit.html.erb` | Em ingles ("Update", "Cancel my account"), sem estilo |
| `devise/sessions/new.html.erb` | Estilizado, porem mistura pt/en |
| `devise/passwords/new.html.erb` | Template padrao Devise, sem estilo |

**Correcao:** Reescrever todas as views do Devise em portugues com o mesmo padrao visual da aplicacao.

---

### 2.5 Pagina Home - Saldo Estatico

**Arquivo:** `app/views/pages/home.html.erb` (linha 11)

```erb
<!-- PROBLEMA: Saldo hardcoded como zero -->
<p class="balance">Saldo atual: <strong>R$ 0,00</strong></p>
```

**Correcao:** Calcular saldo real do usuario:
```erb
<% if user_signed_in? %>
  <% balance = current_user.financial_entries.incomes.sum(:amount) -
               current_user.financial_entries.expenses.sum(:amount) %>
  <p class="balance">Saldo atual: <strong>R$ <%= number_with_precision(balance, precision: 2) %></strong></p>
<% end %>
```

> Nota: Idealmente essa logica deveria estar no model User como metodo `balance`.

---

## 3. Checklist de Implementacao

### Categorias
- [ ] Criar `CategoriesController` com CRUD completo
- [ ] Criar views: index, new, edit, _form
- [ ] Adicionar `resources :categories` nas rotas
- [ ] Proteger exclusao de categorias com transacoes vinculadas

### Orcamento Mensal
- [ ] Criar `MonthlyBudgetsController`
- [ ] Adicionar metodos `spent`, `remaining`, `percentage_used`, `exceeded?` ao model
- [ ] Criar views com barra de progresso visual
- [ ] Adicionar rotas

### Relatorios
- [ ] Adicionar gem `groupdate` ao Gemfile
- [ ] Criar `ReportsController`
- [ ] Criar view com graficos chartkick
- [ ] Corrigir link na navegacao inferior (href="#" -> reports_path)
- [ ] Configurar chartkick no `application.js`

### Devise
- [ ] Reescrever `registrations/new.html.erb` em portugues com campo name
- [ ] Reescrever `registrations/edit.html.erb` em portugues com estilo
- [ ] Estilizar `passwords/new.html.erb`

### Home
- [ ] Corrigir saldo estatico na pagina home

---

## 4. Novas Rotas (resumo)

```ruby
# config/routes.rb - Estado final esperado
Rails.application.routes.draw do
  devise_for :users

  unauthenticated do
    root 'pages#home'
  end

  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
  end

  get 'dashboard', to: 'dashboard#index'

  resources :financial_entries
  resources :categories, except: [:show]
  resources :monthly_budgets, except: [:show, :destroy]
  resources :reports, only: [:index]
end
```

---

## 5. Arquivos a Criar/Modificar

| Arquivo | Acao |
|---|---|
| `app/controllers/categories_controller.rb` | CRIAR |
| `app/views/categories/index.html.erb` | CRIAR |
| `app/views/categories/new.html.erb` | CRIAR |
| `app/views/categories/edit.html.erb` | CRIAR |
| `app/views/categories/_form.html.erb` | CRIAR |
| `app/controllers/monthly_budgets_controller.rb` | CRIAR |
| `app/views/monthly_budgets/index.html.erb` | CRIAR |
| `app/views/monthly_budgets/new.html.erb` | CRIAR |
| `app/views/monthly_budgets/edit.html.erb` | CRIAR |
| `app/views/monthly_budgets/_form.html.erb` | CRIAR |
| `app/controllers/reports_controller.rb` | CRIAR |
| `app/views/reports/index.html.erb` | CRIAR |
| `app/models/monthly_budget.rb` | EDITAR - adicionar metodos |
| `config/routes.rb` | EDITAR - novas rotas |
| `app/views/shared/_bottom_nav.html.erb` | EDITAR - corrigir link relatorios |
| `app/views/pages/home.html.erb` | EDITAR - saldo dinamico |
| `app/views/devise/registrations/new.html.erb` | EDITAR - portugues + estilo + campo name |
| `app/views/devise/registrations/edit.html.erb` | EDITAR - portugues + estilo |
| `Gemfile` | EDITAR - adicionar groupdate |
