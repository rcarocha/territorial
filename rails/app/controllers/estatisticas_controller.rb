require 'estatisticas/estat'
class EstatisticasController < ApplicationController

   def index
      @estatisticas = $ESTATISTICAS

      respond_to do |format|
         format.json
      end
   end

   def show
      id_stat = request['id_stat']
      data = request['data']
      @dados_grafico = ""
      
      case id_stat
         when '01'
            @dados_grafico =
               {:null => false,
                :label => "Proporção dos votos em relação aos votos válidos",
                :type => "line",
                :data => [12, 19, 3, 5, 2, 3],

                :id_stat => id_stat,
               }
         when '02'
            @dados_grafico =
               {:null => false,
                :label => "Proporção de votos por partido",
                :type => "bar",
                :data => [50, 70, 40, 30, 90, 10],

                :id_stat => id_stat,
               }
         else
            @dados_grafico ={
               :null => true,
               :id_stat => id_stat,
               :label => nome,
               :type => "bar",
               :data => [10],
            }
      end
         
      respond_to do |format|
         format.json
      end
   end
end
