require "test_helper"

class TransactionFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @category = create(:category, user: @user)
    sign_in(@user)
  end

  test "complete flow: create, view, edit, delete transaction" do
    # Create
    post financial_entries_path, params: {
      financial_entry: {
        description: "Supermercado",
        amount: 250.50,
        entry_type: "expense",
        date: Date.current,
        category_id: @category.id
      }
    }
    assert_redirected_to financial_entries_path

    entry = @user.financial_entries.last
    assert_equal "Supermercado", entry.description
    assert_equal 250.50, entry.amount.to_f

    # View in list
    get financial_entries_path
    assert_response :success
    assert_match "Supermercado", response.body

    # Edit
    patch financial_entry_path(entry), params: {
      financial_entry: { description: "Supermercado Extra" }
    }
    assert_redirected_to financial_entries_path
    assert_equal "Supermercado Extra", entry.reload.description

    # Delete
    assert_difference -> { @user.financial_entries.count }, -1 do
      delete financial_entry_path(entry)
    end
  end

  test "create income and see it on dashboard" do
    post financial_entries_path, params: {
      financial_entry: {
        description: "Salario",
        amount: 5000,
        entry_type: "income",
        date: Date.current
      }
    }

    get dashboard_path
    assert_response :success
    assert_match "Salario", response.body
  end

  test "filter transactions by type" do
    create(:financial_entry, :income, user: @user, description: "Freelance")
    create(:financial_entry, :expense, user: @user, description: "Aluguel")

    get financial_entries_path(entry_type: 'income')
    assert_match "Freelance", response.body
    assert_no_match "Aluguel", response.body

    get financial_entries_path(entry_type: 'expense')
    assert_match "Aluguel", response.body
    assert_no_match "Freelance", response.body
  end

  test "export transactions as CSV" do
    create(:financial_entry, user: @user, description: "Export Test")

    get financial_entries_path(format: :csv)
    assert_response :success
    assert_match "Export Test", response.body
    assert_match "Data;Descricao;Categoria;Tipo;Valor", response.body
  end
end
