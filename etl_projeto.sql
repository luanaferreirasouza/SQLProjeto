-- Construir uma tabela com o perfil comportamental dos nossos usuário:
-- 1. Quantidade de transações históricas (vida, D7,D14,D28,D566);
-- 2. Dia desde a última transação
-- 3. Idade na base
-- 4. produto mais usado (vida, D7, D14, D28, D56)
-- 5. Saldo de pontos atual;
-- 6. Pontos acumulados positivos  (vida, D7, D14, D28, D56);
-- 7. Pontos acumulados negativos (vida, D7, D14, D28, D56);
--8. Dias da semana mais ativos (D28);
-- 9. período do dia mais ativo (D28);

WITH DifDatas as (
        SELECT idCliente,
                IdTransacao,
                qtdePontos,
                substr(dtcriacao,1,10) as Data,
                julianday('now') - julianday(substr(DtCriacao,1, 10)) as DiffDatas,
                strftime('%w', substr(dtcriacao,1,10)) as DiaSemana,
                CAST (strftime('%H', substr(DtCriacao,1,19)) AS INTEGER) as DtHora
        from transacoes
),
tab_IdadeBase as (

        select idCliente,
                Julianday ('now') - julianday(substr(DtCriacao,1, 10)) as IdadeBase
        from clientes

),

Informacoes01 as (
        select IdCliente,
                COUNT (IdTransacao) AS QtdTransacoesVida,
                count (CASE 
                        WHEN DiffDatas < 7 then IdTransacao else NULL
                        End) as QtdTransacoes7,
                count (CASE 
                        WHEN DiffDatas < 14 then IdTransacao else NULL
                        End) as QtdTransacoes14,
                count (CASE 
                        WHEN DiffDatas < 28 then IdTransacao else NULL
                        End) as QtdTransacoes28,
                count (CASE 
                        WHEN DiffDatas < 566 then IdTransacao else NULL
                        End) as QtdTransacoes566,

                min (diffDatas) as DiasDesdeUlTransacao,
                sum (qtdePontos) as SaldoPontos,

                sum (CASE 
                        WHEN qtdePontos > 0 then qtdePontos else 0
                        End) as SaldoPontosPositivosVida,
                sum (CASE 
                        WHEN qtdePontos > 0 and DiffDatas < 7 then qtdePontos else 0
                        End) as SaldoPontosPositivos7,
                sum (CASE 
                        WHEN qtdePontos > 0 and DiffDatas < 14 then qtdePontos else 0
                        End) as SaldoPontosPositivos14,
                sum (CASE 
                        WHEN qtdePontos > 0 and DiffDatas < 28 then qtdePontos else 0
                        End) as SaldoPontosPositivos28,
                sum (CASE 
                        WHEN qtdePontos > 0 and DiffDatas < 56 then qtdePontos else 0
                        End) as SaldoPontosPositivos56,   

                sum (CASE 
                        WHEN qtdePontos < 0 then qtdePontos else 0
                        End) as SaldoPontosNegativosVida,
                        sum (CASE 
                        WHEN qtdePontos < 0 and  DiffDatas <  7 then qtdePontos else 0
                        End) as SaldoPontosNegativos7,
                sum (CASE 
                        WHEN qtdePontos < 0 and DiffDatas  < 14 then qtdePontos else 0
                        End) as SaldoPontosNegativos14,
                sum (CASE 
                        WHEN qtdePontos < 0 and DiffDatas  < 28 then qtdePontos else 0
                        End) as SaldoPontosNegativos28,
                sum (CASE 
                        WHEN qtdePontos < 0 and DiffDatas  < 56 then qtdePontos else 0
                        End) as SaldoPontosNegativos56  
                from DifDatas
                group by idCliente
),

InformacoesProdutos as (

    SELECT t1.*,
        t2.IdProduto,
        t3.DescNomeProduto
    from DifDatas as t1

    left join transacao_produto as t2
    on t1.IdTransacao = t2.IdTransacao

    left join produtos as t3
    on t2.IdProduto = t3.IdProduto
),

InformacoesContProduto as (
select idCliente,
        IdProduto,
        DescNomeProduto,
        count (IdTransacao) as Produtomaisvida,
        count (CASE
                        WHEN DiffDatas < 7 THEN IdTransacao ELSE NULL END)AS Produtomais7,
        count (CASE
                        WHEN DiffDatas < 14 THEN IdTransacao ELSE NULL END) AS Produtomais14,
        count (CASE
                        WHEN DiffDatas < 28 THEN IdTransacao ELSE NULL END) AS Produtomais28,
        count (CASE
                        WHEN DiffDatas < 56 then IdTransacao ELSE NULL END) AS Produtomais56
from InformacoesProdutos
group by idCliente, IdProduto, DescNomeProduto
),

InformacoesContProduto_row as (
select *,
        row_number () over (PARTITION by idCliente order by Produtomaisvida desc) as rnVida,
        row_number () over (PARTITION by idCliente order by Produtomais7 desc) as rn7,
        row_number () over (PARTITION by idCliente order by Produtomais14 desc) as rn14,
        row_number () over (PARTITION by idCliente order by Produtomais28 desc) as rn28,
        row_number () over (PARTITION by idCliente order by Produtomais56 desc) as rn56

from informacoescontproduto
),

QtdPontosSemana as (
    select idCliente,
            DiaSemana,
            count(IdTransacao) as Atividade
    from difDatas
    where DiffDatas <= 30
    group by 1, 2
),

Row_qtdPontosSemana as (
            select *,
            row_number () over (partition by idCliente order by Atividade DESC) as Numer
            from QtdPontosSemana
),


PeriodoTrasacao as (
        select idCliente,
                CASE 
                        WHEN DTHora BETWEEN 7 and 12 then 'MANHÃ'
                        WHEN DTHora BETWEEN 13 and 18 then 'TARDE'
                        WHEN DTHora BETWEEN 19 and 23 then 'NOITE'
                        ELSE 'MADRUGADA' END AS Periodo,
                count (*) as QtdTransacao
                from DifDatas
                where DiffDatas <= 30
                group by idCliente, periodo
),


Row_PeriodoTransacao as (
select *,
        Row_number () OVER (PARTITION by idCliente order by QtdTransacao desc) as Row
FROM PeriodoTrasacao

),

InformacoesProdutos01 as (

    SELECT t1.*,
        t2.IdadeBase,
        t3.DescNomeProduto as ProdutoMaisUsadoVida,
        t4.DescNomeProduto as ProdutoMaisUsado7,
        t5.DescNomeProduto as ProdutoMaisUsado14,
        t6.DescNomeProduto as ProdutoMaisUsado28,
        t7.DescNomeProduto as ProdutoMaisUsado56,
        COALESCE (t8.DiaSemana, -1) as DiaSemana,
        COALESCE (t9.Periodo, 'SEM INFORMAÇÃO') as Periodo
    from Informacoes01 as t1

    left join tab_IdadeBase as t2
    on t1.idcliente = t2.idCliente

    left join InformacoesContProduto_row as t3
    on t1.idcliente = t3.idcliente
    and t3.rnvida = 1

    left join InformacoesContProduto_row as t4
    on t1.idcliente = t4.idcliente
    and t4.rn7 = 1

    left join InformacoesContProduto_row as t5
    on t1.idcliente = t5.idcliente
    and t5.rn14 = 1

     left join InformacoesContProduto_row as t6
    on t1.idcliente = t6.idcliente
    and t6.rn28 = 1

    left join InformacoesContProduto_row as t7
    on t1.idcliente = t7.idcliente
    and t7.rn56 = 1

    left join Row_qtdPontosSemana as t8
    on t1.idCliente = t8.idCliente
    and t8.Numer = 1 

    left join Row_PeriodoTransacao as t9
    on t1.idCliente = t9.idCliente
    and t9.Row = 1 
)

select *
from InformacoesProdutos01


