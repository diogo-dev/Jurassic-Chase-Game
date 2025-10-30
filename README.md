<h1> Projeto de Programação em Lua (Jogo Jurassic Chase)</h1>
<p> Esse jogo foi desenvolvido como trabalho para a disciplina de <i>Sistemas Distrubuídos</i>. O objetivo era criar um jogo com a arquitetura cliente-servidor para trabalhar com a transmissão de mensagens remotas entre diferentes dispositivos.</p>

<h2>Requisitos para rodar o jogo</h2>
<ul>
  <li> Linguagem Lua
  <li> Framework love2d
  <li> Ter a extenção <i>Love2d Support</i> instalado no seu VsCode
  <li> Outras bibliotecas usadas no jogo (STI, anim8, dkjson, windfield) já estão no repositório
</ul>

<h2>Comandos de execução</h2>
<p>Primeiramente, abra o terminal e rode o seguinte comando: "lua /.server.lua" para iniciar o servidor</p>
<p>Depois entre no arquivo do cliente (main.lua) e pressione as teclas (alt + L) para executá-lo. O comando <i>"love ."</i> só funciona se você colocar o caminho do executável <i>"love.exe"</i> na sua váriável de ambiente PATH.</p>

<h2>Rodando em máquinas diferentes</h2>
<ul>
  <li>Modificar o endereço IP no cliente (colocar o IP real do servidor)</li>
  <li>Configurar o firewall do servidor - Libere a porta 12345 no servidor</li>
  <li>Garantir que ambas as máquinas estejam na mesma rede</li>
</ul>
