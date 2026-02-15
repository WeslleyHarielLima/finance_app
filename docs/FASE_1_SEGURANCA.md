# FASE 1 - Seguranca e Correcoes Criticas

> **Prioridade:** URGENTE
> **Estimativa:** Primeira fase de implementacao
> **Impacto:** Corrige vulnerabilidades que comprometem dados dos usuarios

---

## 1. Diagnostico Atual

### 1.1 Credenciais Hardcoded no Banco de Dados

**Arquivo:** `config/database.yml` (linhas 5-6)

```yaml
# PROBLEMA ATUAL:
default: &default
  adapter: postgresql
  username: weslley
  password: password123    # <-- Exposto no controle de versao
```

**Risco:** Qualquer pessoa com acesso ao repositorio tem acesso direto ao banco de dados.

**Correcao:**
```yaml
# COMO DEVE FICAR:
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: <%= ENV.fetch("DATABASE_USERNAME", "weslley") %>
  password: <%= ENV.fetch("DATABASE_PASSWORD", "") %>
  host: <%= ENV.fetch("DATABASE_HOST", "localhost") %>
  port: <%= ENV.fetch("DATABASE_PORT", 5432) %>
```

**Acao adicional:** Criar arquivo `.env` (e adicionar ao `.gitignore`):
```env
DATABASE_USERNAME=weslley
DATABASE_PASSWORD=password123
DATABASE_HOST=localhost
```

---

### 1.2 Senha Hardcoded no Seeds

**Arquivo:** `db/seeds.rb` (linhas 14, 26, 81)

```ruby
# PROBLEMA ATUAL:
user.password = '137954'              # <-- Senha real exposta
puts "Senha: 137954"                  # <-- Exibida no terminal
```

**Risco:** Senha do usuario de desenvolvimento visivel no historico do git.

**Correcao:**
```ruby
# COMO DEVE FICAR:
default_password = ENV.fetch('SEED_PASSWORD', 'dev_password_123')

user.password = default_password
user.password_confirmation = default_password

puts "Senha: [definida via ENV SEED_PASSWORD]"
```

---

### 1.3 Vazamento de Categorias Entre Usuarios

**Arquivo:** `app/views/financial_entries/_form.html.erb` (linha 24)

```erb
<!-- PROBLEMA ATUAL: -->
<%= form.collection_select :category_id, Category.all, :id, :name,
    { include_blank: true }, class: "form-control" %>
```

**Risco:** `Category.all` exibe categorias de TODOS os usuarios. Um usuario ve e pode associar transacoes as categorias de outro usuario.

**Correcao:**
```erb
<!-- COMO DEVE FICAR: -->
<%= form.collection_select :category_id, @categories, :id, :name,
    { include_blank: "Selecione uma categoria" }, class: "form-control" %>
```

> Nota: `@categories` ja e definida corretamente no controller como `current_user.categories`. O problema esta apenas na view que ignora essa variavel.

---

### 1.4 Devise - Modulos de Seguranca Ausentes

**Arquivo:** `app/models/user.rb` (linhas 3-5)

```ruby
# ESTADO ATUAL:
devise :database_authenticatable, :registerable,
       :recoverable, :rememberable, :validatable
```

**Riscos identificados:**
| Modulo Ausente | Risco |
|---|---|
| `:confirmable` | Qualquer email falso pode registrar conta |
| `:lockable` | Sem protecao contra brute force (tentativas infinitas de senha) |
| `:trackable` | Sem registro de IPs e horarios de login |

**Correcao:**
```ruby
# COMO DEVE FICAR:
devise :database_authenticatable, :registerable,
       :recoverable, :rememberable, :validatable,
       :confirmable, :lockable, :trackable
```

**Migration necessaria:**
```ruby
class AddDeviseModulesToUsers < ActiveRecord::Migration[8.1]
  def change
    # Confirmable
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string
    add_index  :users, :confirmation_token, unique: true

    # Lockable
    add_column :users, :failed_attempts, :integer, default: 0, null: false
    add_column :users, :unlock_token, :string
    add_column :users, :locked_at, :datetime
    add_index  :users, :unlock_token, unique: true

    # Trackable
    add_column :users, :sign_in_count, :integer, default: 0, null: false
    add_column :users, :current_sign_in_at, :datetime
    add_column :users, :last_sign_in_at, :datetime
    add_column :users, :current_sign_in_ip, :string
    add_column :users, :last_sign_in_ip, :string
  end
end
```

---

### 1.5 Gemfile - Dependencia Duplicada

**Arquivo:** `Gemfile` (linhas 66-69)

```ruby
# PROBLEMA ATUAL:
gem 'importmap-rails'
gem 'importmap-rails'   # duplicada
gem 'importmap-rails'   # duplicada
gem 'importmap-rails'   # duplicada
```

**Risco:** Nao causa erro em runtime, mas indica falta de revisao e pode causar conflitos de versao.

**Correcao:** Manter apenas uma linha:
```ruby
gem 'importmap-rails'
```

---

### 1.6 Formulario de Registro - Campo `name` Ausente

**Arquivo:** `app/views/devise/registrations/new.html.erb`

```erb
<!-- ESTADO ATUAL: Usa template padrao do Devise -->
<!-- Campos: email, password, password_confirmation -->
<!-- FALTANDO: campo name (obrigatorio no model User) -->
```

**Risco:** `validates :name, presence: true` no model `User` impede o cadastro. O formulario nao tem o campo, entao o registro sempre falha.

**Correcao - View:**
```erb
<%= f.input :name, required: true, autofocus: true,
    input_html: { autocomplete: "name" } %>
```

**Correcao - Controller (permitir parametro):**
```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
end
```

---

### 1.7 Indices de Banco Ausentes

**Arquivo:** `db/schema.rb`

**Estado atual:** Indices apenas em foreign keys individuais (`user_id`, `category_id`).

**Problema:** Queries frequentes combinam `user_id` + `entry_type` + `date`, sem indice composto.

**Migration necessaria:**
```ruby
class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :financial_entries, [:user_id, :date]
    add_index :financial_entries, [:user_id, :entry_type]
    add_index :financial_entries, [:user_id, :entry_type, :date]
    add_index :monthly_budgets,  [:user_id, :month], unique: true
    add_index :categories,       [:user_id, :name],  unique: true
  end
end
```

---

## 2. Checklist de Implementacao

- [ ] Mover credenciais do `database.yml` para variaveis de ambiente
- [ ] Adicionar gem `dotenv-rails` ao Gemfile (grupo development/test)
- [ ] Criar `.env.example` e adicionar `.env` ao `.gitignore`
- [ ] Substituir `Category.all` por `@categories` no `_form.html.erb`
- [ ] Remover senha hardcoded do `seeds.rb`
- [ ] Adicionar modulos `:confirmable`, `:lockable`, `:trackable` ao Devise
- [ ] Criar migration para campos do Devise
- [ ] Adicionar campo `name` no formulario de registro
- [ ] Configurar `devise_parameter_sanitizer` no `ApplicationController`
- [ ] Remover linhas duplicadas de `importmap-rails` do Gemfile
- [ ] Criar migration com indices compostos
- [ ] Executar `bundle audit` para verificar vulnerabilidades em gems

---

## 3. Arquivos Afetados

| Arquivo | Acao |
|---|---|
| `config/database.yml` | Editar - usar ENV vars |
| `Gemfile` | Editar - adicionar dotenv, remover duplicatas |
| `.gitignore` | Editar - adicionar .env |
| `.env.example` | Criar - template de variaveis |
| `db/seeds.rb` | Editar - remover senha hardcoded |
| `app/models/user.rb` | Editar - adicionar modulos Devise |
| `app/views/financial_entries/_form.html.erb` | Editar - usar @categories |
| `app/views/devise/registrations/new.html.erb` | Editar - adicionar campo name |
| `app/controllers/application_controller.rb` | Editar - sanitizer do Devise |
| `db/migrate/xxx_add_devise_modules.rb` | Criar - migration |
| `db/migrate/xxx_add_performance_indexes.rb` | Criar - migration |
