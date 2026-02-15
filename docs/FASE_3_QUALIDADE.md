# FASE 3 - Qualidade de Codigo e Arquitetura MVC

> **Prioridade:** MEDIA
> **Pre-requisito:** Fases 1 e 2 concluidas
> **Impacto:** Melhora manutencao, performance e padronizacao do codigo

---

## 1. Avaliacao da Arquitetura MVC Atual

### 1.1 Models - Avaliacao

**User** (`app/models/user.rb`)
```
Nota: 6/10
```
| Aspecto | Estado | Observacao |
|---|---|---|
| Associacoes | OK | has_many com dependent: :destroy correto |
| Validacoes | PARCIAL | Falta validacao de email formato, currency, timezone |
| Metodos de negocio | AUSENTE | Sem metodos como `balance`, `total_income_month` |
| Enums | N/A | - |
| Scopes | AUSENTE | Sem scopes uteis |

**FinancialEntry** (`app/models/financial_entry.rb`)
```
Nota: 7/10
```
| Aspecto | Estado | Observacao |
|---|---|---|
| Associacoes | PROBLEMA | `optional: true` em category conflita com NOT NULL no schema |
| Validacoes | OK | Presenca, numericidade, inclusion corretos |
| Scopes | OK | `incomes`, `expenses`, `this_month` bem definidos |
| Metodos | PARCIAL | `formatted_amount` deveria estar em helper/presenter |
| Enums | AUSENTE | `entry_type` usa strings, deveria usar enum |

**Category** (`app/models/category.rb`)
```
Nota: 8/10
```
| Aspecto | Estado | Observacao |
|---|---|---|
| Associacoes | OK | belongs_to user, has_many entries com nullify |
| Validacoes | OK | Presenca e uniqueness scoped corretos |
| Scopes | AUSENTE | Falta scope para ordenacao, busca |

**MonthlyBudget** (`app/models/monthly_budget.rb`)
```
Nota: 5/10
```
| Aspecto | Estado | Observacao |
|---|---|---|
| Associacoes | OK | belongs_to user |
| Validacoes | OK | Presenca e uniqueness scoped |
| Metodos | AUSENTE | Sem metodos de calculo (spent, remaining, etc) |

---

### 1.2 Controllers - Avaliacao

**ApplicationController** (`app/controllers/application_controller.rb`)
```
Nota: 3/10
```
```ruby
# ESTADO ATUAL - praticamente vazio:
class ApplicationController < ActionController::Base
  allow_browser versions: :modern
end
```

**Problemas:**
- Sem `configure_permitted_parameters` para Devise
- Sem `before_action` compartilhado
- Sem tratamento de erros global (RecordNotFound, etc)
- Sem metodos helper para controllers filhos

**Como deveria ser:**
```ruby
class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :monthly_income, :currency])
  end

  private

  def after_sign_in_path_for(resource)
    dashboard_path
  end
end
```

---

**DashboardController** (`app/controllers/dashboard_controller.rb`)
```
Nota: 6/10
```

**Problemas:**
- `@user = current_user` na linha 5 e redundante (current_user ja esta disponivel nas views)
- Logica de calculo de totais deveria estar no model, nao no controller
- `@transactions` na linha 9 faz query que nao e reutilizada (as queries das linhas 12-13 fazem novas queries)

**Refatoracao sugerida:**
```ruby
class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    entries = current_user.financial_entries.this_month

    @total_income = entries.incomes.sum(:amount)
    @total_expenses = entries.expenses.sum(:amount)
    @balance = @total_income - @total_expenses

    @recent_transactions = current_user.financial_entries
      .includes(:category)
      .order(date: :desc, created_at: :desc)
      .limit(5)
  end
end
```

---

**FinancialEntriesController** (`app/controllers/financial_entries_controller.rb`)
```
Nota: 7/10
```

**Pontos positivos:**
- `set_financial_entry` usa `current_user.financial_entries.find` (seguro)
- Strong params corretos
- Includes para evitar N+1

**Problemas:**
- Linhas 20-21: Estatisticas calculam sobre TODAS as entries do usuario, nao filtradas
- `params[:entry_type]` na linha 11 nao e validado (aceita qualquer valor)

**Correcao para filtros:**
```ruby
def index
  @financial_entries = current_user.financial_entries
    .includes(:category)
    .order(date: :desc, created_at: :desc)

  # Validar entry_type antes de filtrar
  if params[:entry_type].in?(%w[income expense])
    @financial_entries = @financial_entries.where(entry_type: params[:entry_type])
  end

  if params[:category_id].present?
    @financial_entries = @financial_entries.where(category_id: params[:category_id])
  end

  @total_income = @financial_entries.incomes.sum(:amount)
  @total_expenses = @financial_entries.expenses.sum(:amount)
  @categories = current_user.categories
end
```

---

### 1.3 Views - Avaliacao

```
Nota geral: 4/10
```

**Problema principal: CSS inline massivo em cada view**

| View | Linhas de CSS inline | Linhas de HTML |
|---|---|---|
| `dashboard/index.html.erb` | 166 linhas (62%) | 103 linhas |
| `financial_entries/index.html.erb` | 141 linhas (61%) | 89 linhas |
| `pages/home.html.erb` | 76 linhas (58%) | 53 linhas |
| `devise/sessions/new.html.erb` | 48 linhas (60%) | 30 linhas |

> Mais de 60% de cada view e CSS repetido dentro de tags `<style>`.

**Problemas identificados:**
1. CSS duplicado entre views (`.transaction-item`, `.transaction-icon`, `.bottom-nav` aparecem em multiplos arquivos)
2. Cores hardcoded repetidas: `#4a6fa5`, `#28a745`, `#dc3545`, `#666`, `#f5f5f5`
3. Bottom nav duplicada: definida inline no `dashboard/index` E como partial em `shared/_bottom_nav`
4. Nenhum uso de CSS variables
5. Arquivo `mobile.scss` existe mas duplica regras do `application.css`
6. Gem `font-awesome-sass` instalada mas nunca utilizada (usa emojis no lugar)

---

### 1.4 Routes - Avaliacao

```
Nota: 7/10
```

```ruby
# ESTADO ATUAL:
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
  get 'pages/home'
end
```

**Problemas:**
- `get 'pages/home'` e redundante (ja coberto pelo root unauthenticated)
- `get 'dashboard'` e redundante (ja coberto pelo authenticated root)
- Faltam rotas para categories, monthly_budgets, reports
- `resources :financial_entries` gera rota `show` que nao e usada (controller tem show vazio)

---

## 2. Refatoracoes Necessarias

### 2.1 Extrair CSS Inline para Stylesheets

**Criar arquivo:** `app/assets/stylesheets/components/variables.css`
```css
:root {
  --color-primary: #4a6fa5;
  --color-success: #28a745;
  --color-danger: #dc3545;
  --color-text: #333;
  --color-text-muted: #666;
  --color-bg: #f5f5f5;
  --color-white: #fff;
  --color-border: #e0e0e0;
  --color-income-bg: #d4edda;
  --color-expense-bg: #f8d7da;
  --color-balance-bg: #cce5ff;
  --radius-sm: 8px;
  --radius-md: 12px;
  --radius-lg: 20px;
  --shadow-sm: 0 2px 8px rgba(0,0,0,0.1);
  --shadow-md: 0 4px 16px rgba(0,0,0,0.1);
}
```

**Criar arquivos de componente:**
- `app/assets/stylesheets/components/buttons.css` - Todos os estilos de botao
- `app/assets/stylesheets/components/cards.css` - Cards e balance cards
- `app/assets/stylesheets/components/transactions.css` - Lista de transacoes
- `app/assets/stylesheets/components/navigation.css` - Bottom nav e header
- `app/assets/stylesheets/components/forms.css` - Formularios
- `app/assets/stylesheets/components/auth.css` - Paginas de login/registro

**Depois:** Remover TODAS as tags `<style>` de dentro das views.

---

### 2.2 Usar Enum no Model

**Arquivo:** `app/models/financial_entry.rb`

```ruby
# ESTADO ATUAL:
validates :entry_type, presence: true, inclusion: { in: ['income', 'expense'] }
scope :incomes, -> { where(entry_type: 'income') }
scope :expenses, -> { where(entry_type: 'expense') }

# COMO DEVE FICAR:
enum :entry_type, { income: 'income', expense: 'expense' }
# O enum ja cria automaticamente: .income, .expense, .income?, .expense?
# e scopes: .income (em vez de .incomes), .expense (em vez de .expenses)
```

> Nota: Como a coluna e string (nao integer), precisa passar o hash com valores explicitamente.

---

### 2.3 Mover Logica de Negocio para Models

**Adicionar ao model User:**
```ruby
class User < ApplicationRecord
  # ... existente ...

  def balance
    financial_entries.incomes.sum(:amount) - financial_entries.expenses.sum(:amount)
  end

  def balance_for_month(date = Date.current)
    range = date.beginning_of_month..date.end_of_month
    entries = financial_entries.where(date: range)
    entries.incomes.sum(:amount) - entries.expenses.sum(:amount)
  end

  def income_for_month(date = Date.current)
    range = date.beginning_of_month..date.end_of_month
    financial_entries.incomes.where(date: range).sum(:amount)
  end

  def expenses_for_month(date = Date.current)
    range = date.beginning_of_month..date.end_of_month
    financial_entries.expenses.where(date: range).sum(:amount)
  end
end
```

---

### 2.4 Mover `formatted_amount` para Helper

**De:** `app/models/financial_entry.rb`
```ruby
# REMOVER do model:
def formatted_amount
  "R$ #{'%.2f' % amount}".gsub('.', ',')
end
```

**Para:** `app/helpers/application_helper.rb`
```ruby
module ApplicationHelper
  def format_currency(amount)
    number_to_currency(amount, unit: "R$ ", separator: ",", delimiter: ".")
  end
end
```

> Regra MVC: Formatacao de exibicao pertence a camada de View (helpers), nao ao Model.

---

### 2.5 Eliminar Bottom Nav Duplicada

**Estado atual:** A bottom nav esta definida em DOIS lugares:
1. `app/views/dashboard/index.html.erb` (linhas 77-102) - Inline, hardcoded
2. `app/views/shared/_bottom_nav.html.erb` - Partial correta

**Correcao:**
- Remover as linhas 77-102 do `dashboard/index.html.erb`
- Adicionar `<%= render 'shared/bottom_nav' %>` no final do dashboard
- Ou mover a bottom nav para o layout `application.html.erb` (condicional para usuarios logados)

**Melhor abordagem - No layout:**
```erb
<!-- app/views/layouts/application.html.erb -->
<body>
  <% if notice %><p class="notice"><%= notice %></p><% end %>
  <% if alert %><p class="alert"><%= alert %></p><% end %>
  <%= yield %>
  <% if user_signed_in? %>
    <%= render 'shared/bottom_nav' %>
  <% end %>
</body>
```

Assim, nenhuma view precisa incluir a bottom nav manualmente.

---

### 2.6 Tratamento de Erros

**Adicionar ao ApplicationController:**
```ruby
rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

private

def record_not_found
  redirect_to root_path, alert: 'Registro nao encontrado.'
end
```

---

## 3. Checklist de Implementacao

### CSS
- [ ] Criar `variables.css` com CSS custom properties
- [ ] Criar arquivos de componente (buttons, cards, transactions, navigation, forms, auth)
- [ ] Remover TODAS as tags `<style>` das views
- [ ] Remover arquivo duplicado `components/mobile.scss`
- [ ] Decidir: usar font-awesome-sass ou remover do Gemfile

### Models
- [ ] Adicionar `enum :entry_type` no FinancialEntry
- [ ] Remover scopes manuais que o enum substitui
- [ ] Corrigir `optional: true` no belongs_to :category (alinhar com schema)
- [ ] Adicionar metodos `balance`, `income_for_month`, `expenses_for_month` ao User
- [ ] Mover `formatted_amount` para ApplicationHelper

### Controllers
- [ ] Refatorar ApplicationController (Devise sanitizer, error handling, after_sign_in_path)
- [ ] Refatorar DashboardController (remover @user redundante, usar scopes do model)
- [ ] Validar `params[:entry_type]` no FinancialEntriesController
- [ ] Remover action `show` vazia ou implementar

### Views
- [ ] Remover bottom nav duplicada do dashboard
- [ ] Mover bottom nav para layout application.html.erb
- [ ] Padronizar uso de `number_to_currency` em vez de formatacao manual

### Routes
- [ ] Remover `get 'pages/home'` (redundante)
- [ ] Remover `get 'dashboard'` (redundante se nao necessario)
- [ ] Limitar financial_entries: `resources :financial_entries, except: [:show]`

---

## 4. Mapa de Dependencias CSS (duplicacoes encontradas)

```
.transaction-item     -> dashboard/index.html.erb + financial_entries/index.html.erb
.transaction-icon     -> dashboard/index.html.erb + financial_entries/index.html.erb
.transaction-amount   -> dashboard/index.html.erb + financial_entries/index.html.erb
.transaction-details  -> dashboard/index.html.erb + financial_entries/index.html.erb
.transaction-meta     -> dashboard/index.html.erb + financial_entries/index.html.erb
.bottom-nav           -> dashboard/index.html.erb + application.css + mobile.scss
.mobile-container     -> application.css + mobile.scss
.btn                  -> pages/home.html.erb + sessions/new.html.erb
.amount               -> dashboard/index.html.erb (unico, mas usa cores hardcoded)
```

---

## 5. Arquivos Afetados

| Arquivo | Acao |
|---|---|
| `app/assets/stylesheets/components/variables.css` | CRIAR |
| `app/assets/stylesheets/components/buttons.css` | CRIAR |
| `app/assets/stylesheets/components/cards.css` | CRIAR |
| `app/assets/stylesheets/components/transactions.css` | CRIAR |
| `app/assets/stylesheets/components/navigation.css` | CRIAR |
| `app/assets/stylesheets/components/forms.css` | CRIAR |
| `app/assets/stylesheets/components/auth.css` | CRIAR |
| `app/assets/stylesheets/components/mobile.scss` | REMOVER (duplicado) |
| `app/models/user.rb` | EDITAR - adicionar metodos de negocio |
| `app/models/financial_entry.rb` | EDITAR - enum, remover formatted_amount |
| `app/helpers/application_helper.rb` | EDITAR - format_currency |
| `app/controllers/application_controller.rb` | EDITAR - error handling, Devise config |
| `app/controllers/dashboard_controller.rb` | EDITAR - refatorar |
| `app/controllers/financial_entries_controller.rb` | EDITAR - validar params |
| `app/views/layouts/application.html.erb` | EDITAR - bottom nav condicional |
| `app/views/dashboard/index.html.erb` | EDITAR - remover CSS e bottom nav inline |
| `app/views/financial_entries/index.html.erb` | EDITAR - remover CSS inline |
| `app/views/pages/home.html.erb` | EDITAR - remover CSS inline |
| `app/views/devise/sessions/new.html.erb` | EDITAR - remover CSS inline |
| `config/routes.rb` | EDITAR - limpar rotas redundantes |
