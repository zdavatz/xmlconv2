#!/usr/bin/env ruby
# PriceContainer -- xmlconv2 -- 22.06.2004 -- hwyss@ywesee.com

module XmlConv
	module Model
		module PriceContainer
			def add_price(price)
				self.prices.push(price)
			end
      def get_price(purpose)
        self.prices.find { |price| price.purpose == purpose }
      end
			def prices
				@prices ||= []
			end
		end
	end
end
