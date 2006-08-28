#!/usr/bin/env ruby
# Conversion::PharmaciePlusBdd -- xmlconv2 -- 18.08.2006 -- hwyss@ywesee.com

require 'rexml/document'
require 'xmlconv/model/address'
require 'xmlconv/model/bdd'
require 'xmlconv/model/bsr'
require 'xmlconv/model/delivery'
require 'xmlconv/model/delivery_item'
require 'xmlconv/model/name'
require 'xmlconv/model/party'

module XmlConv
  module Conversion
    class PharmaciePlusBdd
class << self
  def convert(xml_document)
    bdd = Model::Bdd.new
    REXML::XPath.each(xml_document, '//com-pharma') { |xml_delivery|
      _bdd_add_xml_delivery(bdd, xml_delivery)
    }
    bdd
  end
  def parse(xml_src)
    REXML::Document.new(xml_src)
  end
  def _bdd_add_xml_delivery(bdd, xml_delivery)
    delivery = Model::Delivery.new
    bsr = Model::Bsr.new
    customer = Model::Party.new
    customer.role = 'Customer'
    customer.add_id('ACC', xml_delivery.attributes['ean'])
    bsr.add_party(customer)
    delivery.bsr = bsr
    _delivery_add_xml_header(delivery, xml_delivery)
    REXML::XPath.each(xml_delivery, 'article') { |xml_item|
      _delivery_add_xml_item(delivery, xml_item)  
    }
    bdd.add_delivery(delivery)
    delivery
  end
  def _customer_add_party(customer, id, role)
    party = Model::Party.new
    party.role = role
    party.add_id('ACC', id)
    customer.add_party(party)
    party
  end
  def _delivery_add_xml_header(delivery, xml_delivery)
    xml_order = REXML::XPath.first(xml_delivery, '/commande')
    delivery.add_id('Customer', _latin1(xml_order.attributes['id']))
    if(xml_party = REXML::XPath.first(xml_order, 'fournisseur'))
      _delivery_add_xml_seller(delivery, xml_party)
    end
    _delivery_add_xml_customer(delivery, xml_delivery)
  end
  def _delivery_add_xml_customer(delivery, xml_delivery)
    customer = Model::Party.new
    customer.role = 'Customer'
    ean = 
    _customer_add_party(customer, '1075', 'BillTo')
    ship_to = _customer_add_party(customer, 
                                  _latin1(xml_delivery.attributes['ean']), 
                                  'ShipTo')
    if(xml_header = REXML::XPath.first(xml_delivery, 'livraison'))
      name = Model::Name.new
      if(xml_name = REXML::XPath.first(xml_header, 'last-name'))
        name.last = _latin1(xml_name.text)
      end
      if(xml_name = REXML::XPath.first(xml_header, 'first-name'))
        name.first = _latin1(xml_name.text)
      end
      if(xml_name = REXML::XPath.first(xml_header, 'other-name'))
        name.text = _latin1(xml_name.text)
      end
      customer.name = name
      ship_to.name = name
      _party_add_xml_address(ship_to, xml_header)
    end
    if(xml_email = REXML::XPath.first(xml_delivery, '//groupe/online/email'))
      customer.add_id('email', _latin1(xml_email.text))
    end
    delivery.add_party(customer)
  end
  def _delivery_add_xml_seller(delivery, xml_party)
    party = Model::Party.new
    party.role = 'Seller'
    party.add_id('ACC', _latin1(xml_party.attributes['ean']))
    if(party.acc_id.to_s.empty?)
      party.add_id("ACC", "7601001000681")
    end
    delivery.add_party(party)
  end
  def _delivery_add_xml_item(delivery, xml_item)
    item = Model::DeliveryItem.new
    item.line_no = _latin1(delivery.items.size.next.to_s)
    item.add_id('ET-Nummer', _latin1(xml_item.attributes['ean']))
    item.add_id('Pharmacode', _latin1(xml_item.attributes['pharmacode']))
    item.qty = _latin1(xml_item.attributes['qte-livraison'])
    item.unit = 'PCE'
    delivery.add_item(item)
  end
  def _latin1(str)
    Iconv.iconv('ISO-8859-1//TRANSLIT//IGNORE', 'UTF8', str).first.strip
  rescue
    str
  end
  def _party_add_xml_address(party, xml_header)
    if(xml_address = REXML::XPath.first(xml_header, 'address'))
      address = Model::Address.new
      address.zip_code = _text(xml_address, 'zip')
      address.city = _text(xml_address, 'city')
      if(line = _text(xml_address, 'street'))
        address.add_line(line)
      end
      party.address = address
    end
  end
  def _text(xml_parent, xpath)
    if(xml_element = REXML::XPath.first(xml_parent, xpath))
      _latin1(xml_element.text)
    end
  end
end
    end
  end
end
