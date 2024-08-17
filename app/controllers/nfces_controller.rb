class NfcesController < ApplicationController

  include ActionView::Helpers::NumberHelper
  include FilterByDate


  before_action :set_variables, only: [:index,:export_report]


  def index

    search_filter = params[:search_filter]
    if search_filter.present?
    @nfces = search(search_filter)
    else
      @nfces = current_customer.nfces
    end

      respond_to do |format|
      format.html
      format.xlsx do
        @nfces_xlsx = current_customer.nfces
        render xlsx: 'nfces_xlsx', template: 'nfces/index'
      end
    end
  end


  def show
    @nfce = current_customer.nfces.find_by(id:params[:id])

    if @nfce.nil?
      render template: 'errors/not_found', status: :not_found
      return
    end

      @issuer = @nfce.issuer
      @recipient = @nfce.recipient

     respond_to do |format|
      format.html
      format.xlsx do
        render xlsx: "nfce_#{@nfce.numero_nota}", template: 'nfces/show'
      end
  end
  end


  def export_report
    @start_date = params[:start_date] || Date.today.beginning_of_month
    @end_date = params[:end_date] || Date.today.end_of_month

    respond_to do |format|
      format.xlsx do
        render xlsx: "report_#{@start_date}_#{@end_date}", template: 'nfces/report'
      end
    end
  end

  private

  def search(search_filter)
  nfce_numero_nota = Nfce.arel_table[:numero_nota]
  result =current_customer.nfces.where(nfce_numero_nota.matches("%#{search_filter}%"))
 end

  def set_variables
    @nfces_by_period = nfces_by_month
    @total = total_amount
    @total_value_tributo = total_value_tax(:valor_tributo)
    @total_value_api = total_value_tax(:valor_total_ipi)
    @total_value_icms = total_value_tax(:valor_icms)
  end


  def nfces_by_month
    nfces = filter_by_date(current_customer.nfces,:data_emissao)
  end


  def total_amount
    total_amount = @nfces_by_period.sum {|nfce| nfce.valor_total}
    number_to_currency(total_amount, unit: "R$", separator: ",", delimiter: ".")
  end

  def total_value_tax(column)
    total_amount = @nfces_by_period.joins(:tax).sum(column)
    number_to_currency(total_amount, unit: "R$", separator: ",", delimiter: ".")
  end

  def filter_params
    params.permit(:start_date, :end_date,:search_filter)
  end
 end
