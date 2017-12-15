require 'open-uri'
require 'logger'
require 'json'
#require 'pry'

API_POLITICOS = "http://politicos.olhoneles.org/api/v0/politicians/"

def get_politico_by_cpf(cpf)
	result = JSON.parse(open(API_POLITICOS+"?cpf="+cpf.to_s).read)
	return result
end

#foto
#res["objects"][0]["picture"]
#res = get_politico_by_cpf(10394079191)
#binding.pry