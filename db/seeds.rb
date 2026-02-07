puts "🌱 Iniciando seeds..."

# Limpar dados existentes mantendo estrutura
FinancialEntry.destroy_all
Category.destroy_all
MonthlyBudget.destroy_all

# Criar/atualizar usuário principal
weslley = User.find_or_create_by!(email: 'weslley@gmail.com') do |user|
  user.name = 'Weslley Silva'
  user.monthly_income = 4500.00
  user.currency = 'BRL'
  user.timezone = 'America/Sao_Paulo'
  user.password = '137954'
  user.password_confirmation = '137954'
end

# Atualizar se já existir
weslley.update!(
  name: 'Weslley Silva',
  monthly_income: 4500.00,
  currency: 'BRL',
  timezone: 'America/Sao_Paulo'
)

puts "✅ Usuário: weslley@gmail.com / 137954"
puts "   Nome: #{weslley.name}"
puts "   Renda: R$ #{'%.2f' % weslley.monthly_income}"

# Categorias simplificadas
categories_data = [
  # RECEITAS
  { name: 'Salário', color: '#06D6A0', icon: '💰' },
  { name: 'Freelance', color: '#118AB2', icon: '💻' },
  { name: 'Investimentos', color: '#7209B7', icon: '📈' },
  
  # DESPESAS FIXAS
  { name: 'Aluguel', color: '#10B981', icon: '🏠' },
  { name: 'Condomínio', color: '#059669', icon: '🏢' },
  { name: 'Energia', color: '#FBBF24', icon: '💡' },
  { name: 'Água', color: '#60A5FA', icon: '💧' },
  { name: 'Internet', color: '#8B5CF6', icon: '🌐' },
  { name: 'Celular', color: '#A78BFA', icon: '📱' },
  
  # DESPESAS VARIÁVEIS
  { name: 'Mercado', color: '#EF4444', icon: '🛒' },
  { name: 'Transporte', color: '#3B82F6', icon: '🚗' },
  { name: 'Combustível', color: '#F59E0B', icon: '⛽' },
  { name: 'Farmácia', color: '#DC2626', icon: '💊' },
  { name: 'Lazer', color: '#8B5CF6', icon: '🎮' },
  { name: 'Restaurante', color: '#F97316', icon: '🍽️' },
  { name: 'Academia', color: '#10B981', icon: '💪' },
  
  # DESPESAS OCASIONAIS
  { name: 'Presentes', color: '#EC4899', icon: '🎁' },
  { name: 'Manutenção', color: '#6B7280', icon: '🔧' },
  { name: 'Saúde', color: '#DC2626', icon: '❤️' },
  { name: 'Viagem', color: '#0EA5E9', icon: '✈️' }
]

categories_data.each do |cat_data|
  Category.find_or_create_by!(name: cat_data[:name], user: weslley) do |cat|
    cat.color = cat_data[:color]
    cat.icon = cat_data[:icon]
  end
end

puts "✅ #{Category.count} categorias criadas"

# Criar orçamento do mês atual
current_month = Date.current.beginning_of_month
MonthlyBudget.find_or_create_by!(month: current_month, user: weslley) do |budget|
  budget.total_amount = 3000.00
end

puts "✅ Orçamento mensal: R$ 3.000,00"

puts "\n🎯 Seeds concluídas!"
puts "👉 Acesse: http://localhost:3000"
puts "📧 Email: weslley@gmail.com"
puts "🔐 Senha: 137954"
