class ArqueoController < ApplicationController

  def index
    flash[:mensaje] = "Arqueo de Caja."
    flash[:mensaje] << "<br>Informe de Facturas emitidas/recibidas para las fechas elegidas."
    redirect_to :action => :listado
  end

  def filtrado
    session[("arqueo_filtrado_tipo").to_sym] = params[:filtro][:tipo] if params[:filtro]
    if params[:filtro]
      session[("arqueo_filtrado_condicion").to_sym] = case params[:filtro][:tipo]
        when "dia"
          'YEAR(facturas.fecha) = ' + params[:filtro]["dia(1i)".to_sym] + 
		' AND MONTH(facturas.fecha) = ' + params[:filtro]["dia(2i)".to_sym] + 
		' AND DAY(facturas.fecha) = ' + params[:filtro]["dia(3i)".to_sym]
        when "mes"
          'YEAR(facturas.fecha) = ' + params[:filtro]["mes(1i)".to_sym] +
                ' AND MONTH(facturas.fecha) = ' + params[:filtro]["mes(2i)".to_sym]
        when "anno"
          'YEAR(facturas.fecha) = ' + params[:filtro]["anno(1i)".to_sym]
      end 
    else
      session[("arqueo_filtrado_condicion").to_sym] = nil
    end
    redirect_to :action => :listado
  end

  def listado
    @campos_filtro = [["Día","dia"], ["Mes","mes"], ["Año","anno"]]
    if session[("arqueo_filtrado_condicion").to_sym]
      @resumen = []
      importe_compra=importe_venta=importe_servicio=0
      factura_por_tipo("compras").each do |factura|
        importe_compra += factura.importe 
      end
      factura_por_tipo("ventas").each do |factura|
        importe_venta += factura.importe
      end
      factura_por_tipo("servicios").each do |factura|
        importe_servicio += factura.importe
      end
      @resumen.push([nil, ["concepto","debe","haber","total"]])
      @resumen.push(["ventas", ["Ventas","",importe_venta,importe_venta]])
      @resumen.push(["compras", ["Compras de Productos",importe_compra,"",0-importe_compra]])
      @resumen.push(["servicios", ["Servicios (otros gastos)",importe_servicio,"",0-importe_servicio]])
      @resumen.push(["", ["Iva Soportado",0,"",0]])
      @resumen.push(["", ["Iva Repercutido","",0,0]])
      @resumen.push([nil, ["Bruto Total",importe_compra+importe_servicio,importe_venta,importe_venta-importe_compra-importe_servicio]])
      @resumen.push(["", ["","","",""]])
      @resumen.push(["", ["Iva a Declarar",0,0,0]])
      @resumen.push(["", ["IRPF",0,"",0]])
      @resumen.push(["", ["","","",""]])
      @resumen.push([nil, ["Posición Global",importe_compra+importe_servicio,importe_venta,importe_venta-importe_compra-importe_servicio]])
    end
  end

  def facturas
    if params[:tipo]
      @facturas = factura_por_tipo(params[:tipo])
      render :update do |page|
        page.replace_html params[:update], :partial => "facturas"
      end
    end
  end

  private
    def factura_por_tipo tipo
      case tipo
        when "compras"
          Factura.find :all, :order => 'facturas.fecha DESC, facturas.codigo DESC', :include => "albaran", :conditions => ["albarans.proveedor_id IS NOT NULL AND " + session[("arqueo_filtrado_condicion").to_sym]]
        when "ventas"
          Factura.find :all, :order => 'facturas.fecha DESC, facturas.codigo DESC', :include => "albaran", :conditions => ["albarans.cliente_id IS NOT NULL AND " + session[("arqueo_filtrado_condicion").to_sym]]
        when "servicios"
          Factura.find :all, :order => 'facturas.fecha DESC, facturas.codigo DESC', :conditions => ["facturas.albaran_id IS NULL AND " + session[("arqueo_filtrado_condicion").to_sym]]
      end
    end
end