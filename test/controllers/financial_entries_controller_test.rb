require "test_helper"

class FinancialEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @category = create(:category, user: @user)
    sign_in(@user)
  end

  # Authentication
  test "unauthenticated user is redirected" do
    delete destroy_user_session_path
    get financial_entries_path
    assert_response :redirect
  end

  # Index
  test "index returns success" do
    get financial_entries_path
    assert_response :success
  end

  test "index filters by entry_type income" do
    income = create(:financial_entry, :income, user: @user)
    expense = create(:financial_entry, :expense, user: @user)

    get financial_entries_path(entry_type: 'income')
    assert_response :success
    assert_match income.description, response.body
    assert_no_match expense.description, response.body
  end

  test "index filters by category" do
    entry_with_cat = create(:financial_entry, user: @user, category: @category)
    entry_without = create(:financial_entry, user: @user, category: nil)

    get financial_entries_path(category_id: @category.id)
    assert_response :success
    assert_match entry_with_cat.description, response.body
  end

  test "index search filters by description" do
    create(:financial_entry, user: @user, description: "Supermercado compras")
    create(:financial_entry, user: @user, description: "Salario mensal")

    get financial_entries_path(search: "Supermercado")
    assert_response :success
    assert_match "Supermercado", response.body
  end

  test "index exports CSV" do
    create(:financial_entry, user: @user, description: "Teste CSV")

    get financial_entries_path(format: :csv)
    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match "Teste CSV", response.body
  end

  test "index exports PDF" do
    create(:financial_entry, user: @user, description: "Teste PDF")

    get financial_entries_path(format: :pdf)
    assert_response :success
    assert_equal "application/pdf", response.media_type
  end

  # User isolation
  test "user cannot see other user's entries" do
    other_user = create(:user)
    other_entry = create(:financial_entry, user: other_user, description: "Secreta")

    get financial_entries_path
    assert_no_match "Secreta", response.body
  end

  # Create
  test "create with valid params" do
    assert_difference -> { @user.financial_entries.count }, 1 do
      post financial_entries_path, params: {
        financial_entry: {
          description: "Nova transacao",
          amount: 100,
          entry_type: "expense",
          date: Date.current,
          category_id: @category.id
        }
      }
    end
    assert_redirected_to financial_entries_path
  end

  test "create with invalid params renders new" do
    post financial_entries_path, params: {
      financial_entry: { description: "", amount: -1, entry_type: "expense", date: Date.current }
    }
    assert_response :unprocessable_entity
  end

  # Update
  test "update with valid params" do
    entry = create(:financial_entry, user: @user)
    patch financial_entry_path(entry), params: {
      financial_entry: { description: "Atualizada" }
    }
    assert_redirected_to financial_entries_path
    assert_equal "Atualizada", entry.reload.description
  end

  # Destroy
  test "destroy removes entry" do
    entry = create(:financial_entry, user: @user)
    assert_difference -> { @user.financial_entries.count }, -1 do
      delete financial_entry_path(entry)
    end
    assert_redirected_to financial_entries_url
  end

  # Recurring
  test "create recurring entry" do
    post financial_entries_path, params: {
      financial_entry: {
        description: "Aluguel",
        amount: 1500,
        entry_type: "expense",
        date: Date.current,
        recurring: true,
        recurring_day: 5
      }
    }
    assert_redirected_to financial_entries_path
    entry = @user.financial_entries.last
    assert entry.recurring?
    assert_equal 5, entry.recurring_day
  end
end
