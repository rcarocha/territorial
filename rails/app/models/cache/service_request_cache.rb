require 'digest'
require 'net/http'
require 'open-uri'
require 'logger'


LOGGER_OFFLINE_REQUESTS=Logger.new("#{Rails.root}/log/postponed_requests.log")

def gen_postponed_request(request, file)
   return "curl -g \"#{request}\" -o #{file}"
end

def gen_keyhash(key)
   md5 = Digest::MD5.new
   md5 << key.to_s
   return md5.hexdigest.to_s
end

def get_cached_file(resource_http)
   uri_completa = URI.parse(resource_http)
   hash = gen_keyhash(resource_http)
   cache_file_name = uri_completa.host.to_s + "/" + hash

   return cache_file_name
end

#
# Parameters:
# - request_parameters: parametros a serem utilizados na requisicao (i.e. "Accept")
# - timeout: timeout de leitura em segundos (default 5s)
# - logger: logger a ser utilizado
# - root_dir_cache: diretorio raiz de cache de respostas
def get_remote_resource(resource_http, request_parameters=nil, timeout=5, logger=nil)

  root_dir_cache="#{Rails.root}/tmp"

  if !logger then
    logger = Logger.new(STDOUT)
  end

  inicio = Time.now
  response = {:cached => true, :http_response => Net::HTTPOK, :data => nil, :meta_response => nil}

  Rails.logger.debug("[get_remote_resource] Recuperando " + resource_http.to_s)

  cache = root_dir_cache + "/" + get_cached_file(resource_http)
  if File.exist?(cache) then
    logger.debug("Recurso " + resource_http.to_s + " em cache de DISCO: [" + cache.to_s + "]")
    response[:body] = File.read(cache)
  else
     begin
       if resource_http.start_with?("https://") then
          remote_response = open(resource_http, 'r')
       else
          remote_response = open(resource_http, request_parameters.merge({:read_timeout => 30}))
       end
    rescue => e
         # armazena em arquivo de log comando curl para recuperar offline a requisicao com problema
         LOGGER_OFFLINE_REQUESTS.error(gen_postponed_request(resource_http, get_cached_file(resource_http)))
         raise ErroComunicacao.new(URI.parse(resource_http).host.to_s, e.message)
      end
    response[:meta_response] = remote_response.meta
    response[:body] = remote_response.read()

    if (remote_response.meta != Net::HTTPOK) then
       Rails.logger.debug("[get_remote_resource] Erro no acesso a recurso " + remote_response.meta.to_s)
    end

    dir_file_cache = cache[0..cache.rindex("/")]
    if !File.exist?(dir_file_cache) then
      Dir.mkdir dir_file_cache
    end

    File.open(cache, "w") { |file|
      file.write(response[:body])
      logger.debug("Novo cache recurso " + resource_http.to_s + " em: " + cache.to_s)
    }
  end

  logger.debug "Recurso " + resource_http.to_s + " recuperado em " + ("%.4f" % (Time.now - inicio)) + " s"
  return response

end


# request_to_object_cache

class CacheObjetosRequisicao
   def initialize
      @memcache = {}
   end

   def store(key, objects)
      @memcache[key] = objects
   end

   def cached?(key)
      return (@memcache[key] != nil)
   end

   def get(key)
      return @memcache[key]
   end

   def refresh(key)
      if @memcache[key] then
         @memcache.delete[key]
      end
   end
end

class ErroComunicacao < StandardError

   def initialize(servidor, erro_interno)
      @servidor = servidor
      @erro_interno = erro_interno
   end

   attr_reader :servidor, :erro_interno

   def to_s
      return "Ocorreu um erro no acesso ao servidor " + servidor.to_s + "."
   end

end
