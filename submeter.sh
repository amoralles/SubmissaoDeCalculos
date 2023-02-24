clear
rm faltam >&/dev/null
rm rodando >&/dev/null
rm status >&/dev/null
rm terminados >&/dev/null

#lista dos que estão na fila
qstat -au acmoralles > s
sed '1,5d' s > status
rm s
awk -F" " '{print $4 }' status > rodando


#elimina da fila os cálculos em Hold

cat status | awk -F" " '{print $1 " " $10 }' > st
grep "H$" st | awk '{print $1}' > hold
cat hold | awk -F"." '{print $1}' > jobstokill
rm st hold

tokill=$(cat jobstokill)

for item in $tokill
do
   qdel $item
done


#Lista de todos a serem rodados

#ls *.com | awk -F"." '{print $1}' | sort -n > ./a
#sed '1d' a > aRodar
#rm a

#Lista de iniciados e terminados (com ou sem erro)

grep -e "Error termination request" -e "Normal termination" *.log > t
awk -F"." '{print $1}' t > terminados
rm t

#loop, enquanto houver calculos não terminados
list1=( $(awk -F"." '{print $1}' aRodar) )
list2=( $(cat terminados) )

diff_list=()

faltam=()

while [[ ${#list2[@]} -le ${#list1[@]} || ${#diff_list[@]} -gt 0 ]]
do
diff_list=() # redefine a lista de diferença como vazia

for item in "${list1[@]}"
do
if ! echo "${list2[@]}" | grep -wq "$item"
then
diff_list+=("$item")
fi
done

for item in "${diff_list[@]}"
do
echo "$item" >> faltam
done

faltam=( $(cat ./faltam) )
rodando=( $(cat ./rodando) )

for item in "${faltam[@]}"
do
if ! echo "${rodando[@]}" | grep -wq "$item"
then
qsub GSS_"$item".pbs
fi
done

#atualiza lista 2 deitens terminados
sleep 120 #espera 120 segundos antes de atualizar lista 2 (pode ser ajustado)

grep -e "Error termination request" -e "Normal termination" *.log > t
awk -F"." '{print $1}' t > terminados
list2=( $(cat ./terminados) ) # lê a lista 2 novamente

#atualiza a lista de itens rodando ou na fila
qstat -au acmoralles > s
sed '1,5d' s > status
rm s
awk -F" " '{print $4 }' status > rodando
rodando=( $(cat ./rodando) ) # lê a lista de itens rodando atualmente

#atualiza a lista dos que faltam
faltam=()

#elimina da fila os cálculos em Hold

cat status | awk -F" " '{print $1 " " $10 }' > st
grep "H$" st | awk '{print $1}' > hold
cat hold | awk -F"." '{print $1}' > jobstokill
rm st hold

tokill=$(cat jobstokill)

for item in $tokill
do
   qdel $item
done

done
