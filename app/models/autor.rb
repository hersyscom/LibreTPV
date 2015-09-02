# encoding: UTF-8
#--
#
#################################################################################
# LibreTPV - Gestor TPV para Librerias
# Copyright 2011-2015 Santiago Ramos <sramos@sitiodistinto.net> 
#
#    Este programa es software libre: usted puede redistribuirlo y/o modificarlo 
#    bajo los términos de la Licencia Pública General GNU publicada 
#    por la Fundación para el Software Libre, ya sea la versión 3 
#    de la Licencia, o (a su elección) cualquier versión posterior.
#
#    Este programa se distribuye con la esperanza de que sea útil, pero 
#    SIN GARANTÍA ALGUNA; ni siquiera la garantía implícita 
#    MERCANTIL o de APTITUD PARA UN PROPÓSITO DETERMINADO. 
#    Consulte los detalles de la Licencia Pública General GNU para obtener 
#    una información más detallada. 
#
#    Debería haber recibido una copia de la Licencia Pública General GNU 
#    junto a este programa. 
#    En caso contrario, consulte <http://www.gnu.org/licenses/>.
#################################################################################
#
#++


class Autor < ActiveRecord::Base

  has_many :autor_x_producto
  has_many :producto, through: :autor_x_producto

  has_one :relacion_web, as: :elemento

  validate :sanea_nombre
  validates_uniqueness_of :nombre, :message => "Nombre repetido.", :case_sensitive => false

  before_destroy :verificar_borrado
  after_destroy :eliminar_relacion_web

  # Sincroniza con la BBDD de la web
  def sincroniza_drupal
    # Solo sincroniza si esta definida la conexion con la BBDD
    if Rails.application.config.database_configuration["drupal_#{Rails.env}"]
      # Hace falta una tabla de conversion NID <-> ID
    end
  end

  private
    def sanea_nombre
      self.nombre = nil if self.nombre.upcase == "&NBSP;"
      self.nombre = self.nombre.strip.mb_chars.upcase if self.nombre
      self.errors.add :base, "Nombre no puede estar vacío" if self.nombre.blank?
      return self.errors.empty?
    end

    def verificar_borrado
      errors.add( :base, "No se puede borrar el autor: Hay productos asociados a él." ) unless self.autor_x_producto.empty?
      return self.errors.empty?
    end

    def eliminar_relacion_web
      relacion_web.update_attribute(:eliminar, true) if self.relacion_web
    end

end