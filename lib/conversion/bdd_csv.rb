#!/usr/bin/env ruby
# BddCsv -- xmlconv2 -- 03.12.2007 -- hwyss@ywesee.com

require 'csv'
require 'xmlconv/config'
require 'xmlconv/model/document'
require 'xmlconv/util/application' # needed for bin/bbmb_admin

module XmlConv
  module Conversion
class BddCsv
  class << self
    def convert(bdd)
      bdd.deliveries.collect { |delivery|
        _to_csv(delivery)
      }
    end
    def _formatted_comment(str, replacement=' ')
      str = str.to_s
      u(str.gsub(/[\r\n]+/, replacement))[0,60] unless(str.empty?)
      str
    end
    def _to_csv(delivery)
      result = Model::Document.new
      customer_id, customer_ean13, commit_id, price = nil
      if(customer = delivery.customer)
        result.prefix = customer_id = customer.ids['supplier']
        customer_ean13 = customer.acc_id
      end
      if(customer = delivery.bsr.customer)
        customer_ean13 ||= customer.acc_id
        result.prefix = customer_id ||= customer.ids['supplier']
      end
      result.prefix ||= customer_ean13
      CSV.generate(result) { |writer|
        delivery.items.each { |item|
          if(nprice = item.get_price('NettoPreis'))
            price = nprice.amount
          end
          writer << [
            customer_id,
            customer_ean13,
            Date.today.strftime('%d%m%Y'),
            commit_id,
            item.pharmacode_id,
            item.et_nummer_id,
            item.customer_id,
            item.qty,
            price,
            delivery.customer_id,
            _formatted_comment(delivery.free_text),
          ]
        }
      }
      result
    end
  end
end
  end
end
