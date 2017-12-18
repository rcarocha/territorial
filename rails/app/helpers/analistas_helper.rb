module AnalistasHelper

   def maiusculas_iniciais(nome)
      if nome then
         nome.titleize
      else
         "nulo"
      end
   end

   def codigo_bd_para_humanos(codigo)
      if codigo then
         codigo.to_s.gsub("_"," ").titleize
      else
         "nulo"
      end
   end


   def leaflet_function_getcolor(data=[10,100,200,500,1000])

      colors1 = ['#a63603', '#e6550d', '#fd8d3c', '#fdbe85', '#feedde']

      return_string = 'function getColor(d) { return '
      ind = 0
      data.sort.reverse.each do | valor |
         return_string += "d > #{valor} ? \'#{colors1[ind]}\' : "
         ind = ind + 1
      end
      return_string += " \'#{colors1[colors1.size-1]}\'; }"
      return return_string.html_safe
   end

def leaflet_function_style(nome_propriedade="density")
   return "function style(feature) {
      return {
         weight: 2,
         opacity: 1,
         color: 'white',
         dashArray: '3',
         fillOpacity: 0.7,
         fillColor: getColor(feature.properties.#{nome_propriedade})
      }; }".html_safe
   end

   def leaflet_function_legenda(mapa, valores=[10,100,200,500,1000])
      return "var legend = L.control({position: 'bottomright'});

      legend.onAdd = function (#{mapa}) {

          var div = L.DomUtil.create('div', 'info legend'),
              grades = #{valores.to_s},
              labels = [];

          for (var i = 0; i < grades.length; i++) {
              div.innerHTML +=
                  '<i style=\"background:' + getColor(grades[i] + 1) + '\"></i> ' +
                  grades[i] + (grades[i + 1] ? '&ndash;' + grades[i + 1] + '<br>' : '+');
          }

          return div;
      };
      legend.addTo(#{mapa});".html_safe
   end

   def leaflet_create_info(mapa, titulo, nome_propriedade, unidade, mensagem_adicional="")
      return "var info = L.control();

      var votosLocate = '';
      var votosTotais = '';

      var nameRegiao = '';

      info.onAdd = function (#{mapa}) {
          this._div = L.DomUtil.create('div', 'info'); // Cria a div com a classe info
          this.update();
          return this._div;
      };

      // method that we will use to update the control based on feature properties passes
      //
      info.update = function (props) {
          this._div.innerHTML = '<h4>#{titulo}</h4>' +  (props ?
              '<b>' + props.name + '</b><br />' + props.#{nome_propriedade} + ' #{unidade}'
              : '#{mensagem_adicional}');
          console.log(props);

          //data[0] => votos Locate
          //data[1] => votos Validos
          //data[2] => votos Geral

          if('#{@escopoLocalizacao}' != 'estado')
          {

          config.data.datasets[0].data[0] = ( props ? votosLocate = props.#{nome_propriedade} : votosLocate) ;
          config.data.datasets[0].data[1] = ( props ? votosTotais = props.total_votacao : votosTotais) ;

          props ? nameRegiao = props.name: nameRegiao;
          $('#regiao').html('#{titulo}: ' + nameRegiao);

          $('#votosLocate').html('Votos na Região: '+votosLocate+', Votos Totais: '+votosTotais);
          }
      };
      info.addTo(#{mapa});
      ".html_safe
   end

=begin
var info = L.control();

info.onAdd = function (map) {
    this._div = L.DomUtil.create('div', 'info'); // Cria a div com a classe "info"
    this.update();
    return this._div;
};

// method that we will use to update the control based on feature properties passed
//
info.update = function (props) {
    this._div.innerHTML = '<h4>Brazil Votos/Região </h4>' +  (props ?
        '<b>' + props.name + '</b><br />' + props.density + ' people / mi<sup>2</sup>'
        : 'Selecione um estado');
};
=end

end
