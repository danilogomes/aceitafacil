#encoding: utf-8

module Aceitafacil
    class Card
        include ActiveModel::Model
        include ActiveModel::Validations

        validates :customer_id, :number, :name, :exp_date, presence: true
        validates :exp_date, format: { with: /\d{6}/ }
        validates :number, format: { with: /\d{4}\s\d{4}\s\d{4}\s\d{4}/,message: "Número de cartão inválido" }
         validates :number, length: { minimum: 16 }

        attr_accessor :customer_id, :number, :name, :exp_date
        attr_accessor :token, :card_brand, :last_digits, :status

        def self.find_by_customer_id(customer_id)
            return nil if customer_id.nil?

            @connection = Aceitafacil::Connection.new

            cards = []

            connection_params = {}
            connection_params["customer[id]"] = customer_id
            response = @connection.get("card", connection_params)

            json = JSON.parse(response.body)
            
            return [] if json["card"].nil?

            json["card"].each do |remote_card|
                card = Card.new(token: remote_card["token"], card_brand: remote_card["card_brand"], last_digits: remote_card["last_digits"])
                cards << card
            end

            return cards
        end

        def self.remove(card)
            return nil  if card.nil?

            delete_params = {}

            delete_params["customer[id]"] = card.customer_id
            delete_params["card[token]"] = card.token

            @connection = Aceitafacil::Connection.new

            response = @connection.delete("card", delete_params)

            json = JSON.parse(response.body)

            card = Card.new(token: json["card"][0]["token"], status: json["card"][0]["status"])

            return card
        end

        def initialize(params = {})
            @connection = Aceitafacil::Connection.new

            self.customer_id = params[:customer_id]
            self.number = params[:number]
            self.name = params[:name]
            self.exp_date = params[:exp_date]
            self.status = params[:status]
            self.token = params[:token]
            self.last_digits = params[:last_digits]
            self.card_brand = params[:card_brand]
        end

        def params
            params = {}

            params["customer[id]"] = self.customer_id
            params["card[name]"] = self.name
            params["card[number]"] = self.number.gsub(" ", "")
            params["card[exp_date]"] = self.exp_date

            return params
        end

        def save
            return false if not self.valid?
            response = @connection.post("card", params)

            json = JSON.parse(response.body)
            
            if json["errors"]
                self.errors.add(:number, json["errors"][0]["message"])
                return false
            else
                self.token = json["card"][0]["token"]
                self.card_brand = json["card"][0]["card_brand"]
                self.last_digits = json["card"][0]["last_digits"]

                return response
            end    
        end
    end
end