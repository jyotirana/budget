require 'test_helper'
require_relative 'layout_tests'

class WalletsControllerTest < ActionController::TestCase
  include LayoutTests

  def setup
    sign_in users(:user_with_wallet_1)
  end

  def after
    DatabaseCleaner.clean
  end

  test "should get new" do
    get :new
    assert_response :success
    assert_not_nil assigns(:wallet)
  end

  test "should be form on page" do
    get :new
    assert_select 'form' do
      assert_select 'input#wallet_name'
      assert_select 'input#wallet_amount'
      assert_select 'input[TYPE=submit]'
    end
  end

  test "should create budget and redirect to new with notice" do
    post :create, wallet: { name: 'Some title' }
    wallet = Wallet.new(@request.params[:wallet])
    assert_redirected_to :wallets
    assert_equal I18n.t('flash.wallet_success', name: wallet.name), flash[:notice]
  end

  test "should show error when name is empty" do
    post :create, wallet: { name: '' }
    assert_tag tag: 'span', content: I18n.t('errors.messages.blank')
    assert_template :new
  end

  test "on form page should be placeholder for planning budget with expenses" do
    get :new
    assert_tag tag: 'div', attributes: { id: 'budget_plan' }
  end

  test "if no wallets are present should redirect to new budget page" do
    sign_in users(:user_without_wallet)
    get :index
    assert_redirected_to :new_wallet
  end

  test "if wallets are present should show table with wallets list" do
    post :create, wallet: { name: 'Budget name', amount: 500, user_id: 1 }
    get :index
    assert_tag tag: 'table', attributes: { class: 'table table-striped' }
  end

  test "after create wallet, amount should be equal 500" do
    post :create, wallet: { name: 'Budget name', amount: 500, user_id: 1 }
    wallet = Wallet.new(@request.params[:wallet])
    assert_equal wallet.amount, 500
  end

  test "after create wallet, amount should be not equal 200" do
    post :create, wallet: { name: 'Budget name', amount: 500, user_id: 1 }
    wallet = Wallet.new(@request.params[:wallet])
    assert_not_equal wallet.amount, 200
  end

  test "if wallet with 2 expenses was successfuly created, sum of amount should be 40" do
    post :create, wallet: { name: 'Budget name', user_id: 1, expenses_attributes: { 0=> { name: 'food', amount: 34, execution_date: '2012-11-12' }, 1=> { name: 'food2', amount: 6, execution_date: '2012-11-12' } } }
    wallet = Wallet.new(@request.params[:wallet])
    @sum = 0
    wallet.expenses.each do |e|
      @sum+=e.amount
    end
    assert_equal @sum, 40
  end

  test "should not update wallet if name is empty" do
    put :update, id: wallets(:wallet_1), wallet: {user_id: 1, amount: 200, name: ''}
    assert_template :edit
    assert_tag :tag => 'span', :content => I18n.t('errors.messages.blank')
  end

  test "should not update other users wallet" do
    put :update, id: wallets(:wallet_3), wallet: {user_id: 1, amount: 200, name: 'something'}
    assert_redirected_to :wallets
    assert_equal I18n.t('flash.no_record', model: I18n.t('activerecord.models.wallet')), flash[:notice]
  end

  test "should update user wallet" do
    put :update, id: wallets(:wallet_1), wallet: {user_id: 1, amount: 200, name: 'something'}
    assert_redirected_to :wallets
    assert_equal I18n.t('flash.update_one', model: I18n.t('activerecord.models.wallet')), flash[:notice]
  end
  test "should destroy wallet and redirect to wallets" do
    assert_difference('Wallet.count', -1) do
      delete :destroy, id: wallets(:wallet_1).id
    end
    assert_equal  I18n.t('flash.delete_one', model: I18n.t('activerecord.models.wallet')), flash[:notice]
    assert_redirected_to :wallets
  end

  test "should not destroy expense with belongs to another user" do
    assert_no_difference('Wallet.count') do
      delete :destroy, id: wallets(:wallet_3).id
    end
    assert_equal I18n.t('flash.no_record', model: I18n.t('activerecord.models.wallet')), flash[:notice]
    assert_redirected_to :wallets
  end

  test "should not destroy expense does not exist" do
    wallets(:wallet_1).destroy
    assert_no_difference('Wallet.count') do
      delete :destroy, id: 100
    end
    assert_equal I18n.t('flash.no_record', model: I18n.t('activerecord.models.wallet')), flash[:notice]
    assert_redirected_to :wallets
  end

end
