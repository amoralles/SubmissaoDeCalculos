#!/bin/csh

rm faltam rodando status terminados

# lista dos que estão na fila

qstat -au acmoralles > s

sed '1,5d' s > status

rm s

cat status | awk -F" " '{print $4 }' > rodando

#Lista de todos a serem rodados

#ls *.com | awk -F"." '{print $1}' | sort -n  > ./a
#sed '1d' a > aRodar
#rm a

#Lista de iniciados e terminados (com ou sem erro)

grep "termination" *.log > t
cat t | awk -F"." '{print $1}' > terminados
rm t

# loop, enquanto houver calculos n�o terminados
set list1 = `cat ./aRodar`
set list2 = `cat ./terminados`

set diff_list = ()

while ($#list2 <= $#list1 || $#diff_list > 0)
  set diff_list = () # redefine a lista de diferença como vazia
  
  foreach item ( $list1 )
    echo "$list2" | grep -wq "$item"
    if ($? == 1 ) then
      set diff_list = ( $diff_list $item )
    endif
  end

  foreach item ($diff_list)
    echo $item >> faltam
  end
  
  set faltam = `cat ./faltam`
  set rodando = `cat ./rodando`

  foreach item ($faltam)
    echo "$rodando" | grep -wq "$item"
    if ($? == 1) then
      qsub GSS_$item.pbs
    endif
  end

# atualiza lista 2 deitens terminados
  sleep 120 #espera 120 segundos antes de atualizar lista 2 (pode ser ajustado)
  

  grep "termination" *.log > t
  cat t | awk -F"." '{print $1}' > terminados 
  set list1 = `cat ./terminados` # lê a lista 2 novament

#atualiza a lista de itens rodando ou na fila
  qstat -au acmoralles > s
  sed '1,5d' s > status
  rm s
  cat status | awk -F" " '{print $4 }' > rodando
  set rodando = `cat ./rodando` # lê a lista de ites rodando atualmente

end


