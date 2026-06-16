
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    -- 市町村基礎ファイル（退職保険料・保険料軽減額）作成パッケージ
    -- %usage
    -- 賦課限度額控除後試算ワーク、市町村基礎ファイル（退職保険料・保険料軽減額）
    -- 作成ワークを更新します。
    -- %version 1.2.1 16/09/23 RM-EA-16-0024 国保事業費納付金等算定標準システムへの対応
    -- %update  1.2.1 17/02/24 RM-EA-16-0048 市町村基礎ファイル作成処理の未対応事項への対応
    -- %update  2.0.0 17/11/17 RM-EA-17-0045 市町村基礎ファイル（退職保険料・保険料軽減額）作成処理の未対応事項への対応
    -- %update  2.0.1 18/10/26 RM-EA-17-0051 市町村基礎ファイル（退職保険料・保険料軽減額）における退職被保険者等分納付金の算出方法変更
    -- %update  2.0.3 20/02/14 RM-EA-19-0002 所得照会機能改善
    -- %update  2.0.4 21/06/04 RM-EA-20-0027 令和３年度税制改正対応（３次）
    -- %update  2.0.5 22/04/15 RM-EA-22-0002 年度内に75歳到達になっても平等割額が軽減対象にならない
    -- %update  2.0.6 23/08/25 RM-EA-23-0011 特定世帯に係る平等割軽減誤り
    -- %update  2.0.7A 25/08/29 RM-EA-25-0010 子ども・子育て支援金制度の創設対応（１次）
    -- %version 1.0.0 行政SaaS
    -- %update  1.0.0 25/11/28 RG-EA-25-0071 各種一覧等のレスポンス改善
    -- %update  1.1.0 26/xx/xx RG-EA-25-0002 子ども・子育て支援金制度の創設対応（３次）
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

    -- 軽減額
    DROP TYPE IF EXISTS EAPG_SichosonKisoFileT$TY_Keigen_R;
    DROP TYPE IF EXISTS EAPG_SichosonKisoFileT$TY_Sisan_T;
    DROP TYPE IF EXISTS EAPG_SichosonKisoFileT$TY_Sisan_R;

CREATE TYPE  EAPG_SichosonKisoFileT$TY_Keigen_R AS (
        KintoWrKei     numeric(7, 0),
        ByodoWrKei     numeric(7, 0),
        ByodoWrHKei    numeric(7, 0));

CREATE TYPE  EAPG_SichosonKisoFileT$TY_Sisan_R AS (
        FukaNendo     numeric(4, 0),
        KokuhoNo      numeric(8, 0),
        SetainusiNo   numeric(15, 0),
        UtiwakeKbn    numeric(2, 0),
        ShtktGak      numeric(11, 0),
        SisantGak     numeric(11, 0),
        Hihosu        numeric(3, 0),
        ByodohKbn     numeric(1, 0),
        ShtKwr        numeric(11, 0),
        Sisanwr       numeric(11, 0),
        KinTowr       numeric(11, 0),
        ByoDowr       numeric(11, 0),
        KintowrKei    numeric(11, 0),
        ByodowrKei    numeric(11, 0),
        SanteiGak     numeric(11, 0),
        RegDate       timestamp,
        RegstaffId    varchar(32)
);

CREATE TYPE  EAPG_SichosonKisoFileT$TY_Sisan_T AS (
       TIXSisan EAPG_SichosonKisoFileT$TY_Sisan_R[]
);
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    -- 計算パラメータを取得します。
    -- %usage
    -- 市町村基礎ファイルパラメータマスタ、計算パラメータ１、
    -- 計算パラメータ２の各マスタから、計算パラメータを取得します。
    -- %param pFukaNendo       賦課年度
    -- %param pKankatuCd       管轄コード
    -- %return 戻り値
    --     {*}  0 正常終了
    --     {*}  1 異常終了
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    CREATE OR REPLACE FUNCTION EAPG_SichosonKisoFileT$GetKeisanParam(pFukaNendo     IN OUT  numeric,
                            pKankatuCd     IN      numeric,
    pRet OUT numeric)


AS $$

    DECLARE
        EAPG_SichosonKisoFileT$SichosonKisoFileParm_ EATM_SichosonKisoFileParm[];
        EAPG_SichosonKisoFileT$FukaKeisanParm2_ EATM_FukaKeisanParm2[];
        EAPG_SichosonKisoFileT$FukaKeisanParm1_ EATM_FukaKeisanParm1%ROWTYPE;
        SQLCODE varchar;
        lParam       varchar(1000);
        lErrMsg      varchar(1000);
        lKankatuCd   numeric;
    BEGIN

        CALL CBPG_PkgVariable$Init();

        -- 一時テーブルの初期化

        PERFORM CBPG_PkgVariable$InitValue('EAPG_SichosonKisoFileT', 'SichosonKisoFileParm_', EAPG_SichosonKisoFileT$SichosonKisoFileParm_);

        PERFORM CBPG_PkgVariable$InitValue('EAPG_SichosonKisoFileT', 'FukaKeisanParm2_', EAPG_SichosonKisoFileT$FukaKeisanParm2_);

        PERFORM CBPG_PkgVariable$InitValue('EAPG_SichosonKisoFileT', 'FukaKeisanParm1_', EAPG_SichosonKisoFileT$FukaKeisanParm1_);

        lParam  := concat('賦課年度:' , pFukaNendo , ',管轄コード:' , pKankatuCd);

        -- 初期化
        PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'FukaKeisanParm1_' , NULL::varchar);
        FOR i IN 1 .. makieya.array_length(CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'FukaKeisanParm2_', EAPG_SichosonKisoFileT$FukaKeisanParm2_)) LOOP
            PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'FukaKeisanParm2_' , ARRAY[]::EATM_FukaKeisanParm2[]);
        END LOOP;

        FOR i IN 1 .. makieya.array_length(CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'SichosonKisoFileParm_', EAPG_SichosonKisoFileT$SichosonKisoFileParm_)) LOOP
            PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'SichosonKisoFileParm_' , ARRAY[]::EATM_SichosonKisoFileParm[]);
        END LOOP;

        -- 管轄コードが未選択の場合、0(全市)を設定する
        IF pKankatuCd = -1 THEN
            lKankatuCd := 0;
        ELSE
            lKankatuCd := pKankatuCd;
        END IF;


        DECLARE
            -- 賦課計算パラメータ１より、軽減区分等を抽出するカーソル
            csrFukaKeisanParm1 CURSOR FOR
                SELECT *
                  FROM EATM_FukaKeisanParm1
                 WHERE FukaNendo = pFukaNendo
                   AND KankatuCd = lKankatuCd
                 ORDER BY FukaNendo DESC;
            recFukaKeisanParm1    record;
        BEGIN
            -- 賦課計算パラメータ１取得
            FOR recFukaKeisanParm1 IN csrFukaKeisanParm1 LOOP
                PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'FukaKeisanParm1_' , recFukaKeisanParm1);

                -- 現年度が取得できたら、処理脱出
                IF recFukaKeisanParm1.Fukanendo = pFukaNendo THEN
                    EXIT;
                END IF;
            END LOOP;

        END;

        -- パラメータ1マスタの取得賦課年度を返す
        EAPG_SichosonKisoFileT$FukaKeisanParm1_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'FukaKeisanParm1_', EAPG_SichosonKisoFileT$FukaKeisanParm1_);
        pFukaNendo := EAPG_SichosonKisoFileT$FukaKeisanParm1_.Fukanendo;

        DECLARE
            -- 賦課計算パラメータ２より、税[料]率等を抽出するカーソル
            csrFukaKeisanParm2 CURSOR FOR
                SELECT *
                  FROM EATM_FukaKeisanParm2
                 WHERE FukaNendo = pFukaNendo
                   AND KankatuCd = lKankatuCd
                 ORDER BY HokenzeiShu;
            recFukaKeisanParm2    record;
        BEGIN
            -- 賦課計算パラメータ２取得
            FOR recFukaKeisanParm2 IN csrFukaKeisanParm2 LOOP
                EAPG_SichosonKisoFileT$FukaKeisanParm2_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'FukaKeisanParm2_', EAPG_SichosonKisoFileT$FukaKeisanParm2_);
                EAPG_SichosonKisoFileT$FukaKeisanParm2_[recFukaKeisanParm2.HokenzeiShu] := recFukaKeisanParm2;
                PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'FukaKeisanParm2_', EAPG_SichosonKisoFileT$FukaKeisanParm2_);
            END LOOP;

        END;

        DECLARE
            -- 市町村基礎ファイルパラメータマスタより、税[料]率等を抽出するカーソル
            csrSichosonKisoFileParm CURSOR FOR
                SELECT *
                  FROM EATM_SichosonKisoFileParm
                 WHERE FukaNendo = pFukaNendo
                   AND KankatuCd = lKankatuCd
                 ORDER BY HokenzeiShu;
            recSichosonKisoFileParm    record;
        BEGIN
            -- 市町村基礎ファイルパラメータマスタ取得
            FOR recSichosonKisoFileParm IN csrSichosonKisoFileParm LOOP
                EAPG_SichosonKisoFileT$SichosonKisoFileParm_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'SichosonKisoFileParm_', EAPG_SichosonKisoFileT$SichosonKisoFileParm_);
                EAPG_SichosonKisoFileT$SichosonKisoFileParm_[recSichosonKisoFileParm.HokenzeiShu] := recSichosonKisoFileParm;
                PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'SichosonKisoFileParm_', EAPG_SichosonKisoFileT$SichosonKisoFileParm_);
            END LOOP;

        END;

        pRet = /*RETURN_TRUE*/0;
        RETURN;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS SQLCODE = RETURNED_SQLSTATE;
            lErrMsg := concat(/*THIS_PACKAGE*/'EAPG_SichosonKisoFileT' , '.GetKeisanParam:' , SQLCODE , ' ' , SQLERRM , ' ');
            CALL CBPG_ERRLOG$PRC_Logging(concat(lErrMsg , lParam));
            pRet = /*RETURN_FALSE*/1;
            RETURN;

    END;

$$ LANGUAGE plpgsql;

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    -- 加入状態テーブルを作成します。
    -- %usage
    -- 指定された基準日現在の資格情報を参照して、世帯主と世帯構成員の
    -- 加入状態を決定し、テーブルを作成します。
    -- %param pFukaNendo       賦課年度
    -- %param pKokuhoNo        国保番号
    -- %param pKokuhoRNo       国保履歴番号
    -- %param pSetainusiNo     世帯主番号
    -- %param pSikakuKijunYmd  資格基準年月日
    -- %param pCnt             被保険者カウント
    -- %param pHenkoMM         金額変更月
    -- %param pShoriKbn        処理区分
    -- %return 戻り値
    --     {*}  0 正常終了
    --     {*}  1 異常終了
    --     {*}  3 処理対象外
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    CREATE OR REPLACE FUNCTION EAPG_SichosonKisoFileT$NewSikakuFuka(pFukaNendo      IN   numeric,
                           pKokuhoNo       IN   numeric,
                           pKokuhoRNo      IN   numeric,
                           pSetainusiNo    IN   numeric,
                           pSikakuKijunYmd IN   timestamp(0) without time zone,
                           pCnt            OUT  numeric,
    pRet OUT numeric)


AS $$

    DECLARE
        EAPG_SichosonKisoFileT$NusiKanyuJ_ EATB_NusikanyuJ%ROWTYPE;
        item EATB_KojinKanyuJ;
        EAPG_SichosonKisoFileT$KojinKanyuJ_ EATB_KojinKanyuJ[];
        SQLCODE varchar;
        NusiKbn_tbl      numeric[];
        KojinKbn_tbl     numeric[];
        Hihosu_tbl       numeric[];
        KijunYmd_tbl     timestamp(0) without time zone[];
        lSouJiyuCd       EATB_SikakuTSRireki.SouJiyuCd%TYPE;
        lHihosu          integer;
        i                integer;
        lNusiKbn         numeric;
        lKojinKbn        numeric;
        lNusiFlg         numeric(1);
        lFlg             numeric(1);
        lParam           varchar(1000);
        lErrMsg          varchar(1000);
        -- @as 17/01/27 RM-EA-16-0048
        lBymd            CETB_PersonRireki.Bymd%TYPE;
        lBymdHonnin      CETB_PersonRireki.Bymd%TYPE;
        -- @ae 17/01/27 RM-EA-16-0048
    BEGIN

        CALL CBPG_PkgVariable$Init();

        -- 一時テーブルの初期化

        PERFORM CBPG_PkgVariable$InitValue('EAPG_SichosonKisoFileT', 'NusiKanyuJ_', EAPG_SichosonKisoFileT$NusiKanyuJ_);

        PERFORM CBPG_PkgVariable$InitValue('EAPG_SichosonKisoFileT', 'KojinKanyuJ_', EAPG_SichosonKisoFileT$KojinKanyuJ_);

        lParam  := concat('賦課年度:' , pFukaNendo , ',国保番号:' , pKokuhoNo  , ',世帯主番号:' , pSetainusiNo);

        -- パッケージテーブルTYPE初期化
        PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'NusiKanyuJ_' , NULL::varchar);             -- 世帯主加入状態
        PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'KojinKanyuJ_' , ARRAY[]::EATB_KojinKanyuJ[]);             -- 個人加入状態

        -- ローカルテーブルTYPE初期化
        FOR i IN /*EAPG_Cnst.IDX_APR1*/0 .. /*EAPG_Cnst.IDX_MAR*/12 LOOP
            NusiKbn_tbl[i]  := /*EAPG_Cnst.NUSIJ_NASI*/0;           -- 世帯主月別加入状態
            KojinKbn_tbl[i] := /*EAPG_Cnst.KOJINJ_NASI*/0;          -- 個人月別加入状態
            Hihosu_tbl[i]   := 0;                              -- 被保険者数
        END LOOP;

        -- 加入状態を判断する基準日
        KijunYmd_tbl[/*EAPG_Cnst.IDX_APR1*/0] := makieya.TO_DATE(concat(pFukaNendo , '/04/02'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_APR*/1]  := makieya.TO_DATE(concat(pFukaNendo , '/05/01'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_MAY*/2]  := makieya.TO_DATE(concat(pFukaNendo , '/06/01'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_JUN*/3]  := makieya.TO_DATE(concat(pFukaNendo , '/07/01'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_JUL*/4]  := makieya.TO_DATE(concat(pFukaNendo , '/08/01'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_AUG*/5]  := makieya.TO_DATE(concat(pFukaNendo , '/09/01'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_SEP*/6]  := makieya.TO_DATE(concat(pFukaNendo , '/10/01'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_OCT*/7]  := makieya.TO_DATE(concat(pFukaNendo , '/11/01'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_NOV*/8]  := makieya.TO_DATE(concat(pFukaNendo , '/12/01'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_DEC*/9]  := makieya.TO_DATE(concat(pFukaNendo + 1 , '/01/01'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_JAN*/10]  := makieya.TO_DATE(concat(pFukaNendo + 1 , '/02/01'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_FEB*/11]  := makieya.TO_DATE(concat(pFukaNendo + 1 , '/03/01'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_MAR*/12]  := makieya.TO_DATE(concat(pFukaNendo + 1 , '/04/01'),'YYYY/MM/DD');

        -- ≪世帯主加入状態区分の設定≫
        -- 世帯主履歴テーブルより、年度内において世帯主に該当している人を抽出するカーソル
        DECLARE
            -- 世帯主履歴テーブルより、年度内において世帯主に該当している人を抽出するカーソル
            csrNusi CURSOR FOR
                SELECT GaitoYmd
                     , HigaitoYmd
                     , NusiKbn
                  FROM EATB_NusiRireki
                 WHERE KokuhoNo = pKokuhoNo
                   AND KokuhoRNo = pKokuhoRNo
                   AND SetainusiNo = pSetainusiNo
                   AND GaitoYmd <= pSikakuKijunYmd
                   AND (HigaitoYmd > pSikakuKijunYmd
                    OR  makieya.isEmpty(HigaitoYmd) = TRUE )
                 ORDER BY GaitoYmd;
        BEGIN
            FOR recNusi IN csrNusi LOOP

                -- 世帯主区分をセット
                lNusiKbn := recNusi.NusiKbn;

                -- 非該当年月日が入っている場合
                IF makieya.isEmpty(recNusi.HigaitoYmd) = FALSE   THEN

                    -- 全部喪失か判断するため、被保険者数を取得しておく
                    SELECT COUNT(*)
                      INTO STRICT lHihosu
                      FROM EATB_SikakuTSRireki
                     WHERE KokuhoNo = pKokuhoNo
                       AND KokuhoRNo = pKokuhoRNo
                       AND SikakuKbn = /*EAPG_Cnst.SIKAKU_KOKUHO*/1
                       AND TokuYmd <= pSikakuKijunYmd
                       AND ((SouYmd > makieya.dateadd(pSikakuKijunYmd, 1)  AND SouJiyuCd     IN (/*JIYUCD_SKANYU*/32, /*JIYUCD_KKANYU*/35, /*JIYUCD_SNINTEI*/36))
                         OR (SouYmd > pSikakuKijunYmd      AND SouJiyuCd NOT IN (/*JIYUCD_SKANYU*/32, /*JIYUCD_KKANYU*/35, /*JIYUCD_SNINTEI*/36))
                         OR makieya.isEmpty(SouYmd)  = TRUE );

                    -- 非該当年月日が資格基準年月日の翌日の場合 → 終了事由が「社保加入」であれば、資格保有日は資格適用終了日の前々日まで
                    -- ※後期高齢加入（年齢到達）、後期高齢加入（障害認定）の場合も同様の処理を行う
                    IF recNusi.HigaitoYmd = makieya.dateadd(pSikakuKijunYmd, 1) THEN

                        -- 普通世帯主の場合･･･本人の終了事由を参照
                        IF recNusi.NusiKbn = /*EAPG_Cnst.NUSIJ_FUNUSI*/1 THEN
                            SELECT MAX(SouJiyuCd)
                              INTO STRICT lSouJiyuCd
                              FROM EATB_SikakuTSRireki
                             WHERE KokuhoNo = pKokuhoNo
                               AND KokuhoRNo = pKokuhoRNo
                               AND PersonNo = pSetainusiNo
                               AND SikakuKbn = /*EAPG_Cnst.SIKAKU_KOKUHO*/1
                               AND SouYmd = makieya.dateadd(pSikakuKijunYmd, 1);

                            IF lSouJiyuCd IN (/*JIYUCD_SKANYU*/32, /*JIYUCD_KKANYU*/35, /*JIYUCD_SNINTEI*/36) THEN
                                -- 全部喪失の場合は、世帯主以外
                                IF lHihosu = 0 THEN
                                    lNusiKbn := /*EAPG_Cnst.NUSIJ_NASI*/0;
                                -- 一部喪失の場合は、擬制世帯主
                                ELSE
                                    lNusiKbn := /*EAPG_Cnst.NUSIJ_GINUSI*/2;
                                END IF;
                            END IF;

                        -- 擬制世帯主の場合･･･被保険者の終了事由を参照（全部喪失の場合のみ）
                        ELSE
                            IF lHihosu = 0 THEN
                                SELECT MAX(SouJiyuCd)
                                  INTO STRICT lSouJiyuCd
                                  FROM EATB_SikakuTSRireki
                                 WHERE KokuhoNo = pKokuhoNo
                                   AND KokuhoRNo = pKokuhoRNo
                                   AND SikakuKbn = /*EAPG_Cnst.SIKAKU_KOKUHO*/1
                                   AND SouYmd = makieya.dateadd(pSikakuKijunYmd, 1);

                                IF lSouJiyuCd IN (/*JIYUCD_SKANYU*/32, /*JIYUCD_KKANYU*/35, /*JIYUCD_SNINTEI*/36) THEN
                                    lNusiKbn := /*EAPG_Cnst.NUSIJ_NASI*/0;
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            END LOOP;
        END;

        -- 世帯主区分を設定する
        FOR i IN /*EAPG_Cnst.IDX_APR1*/0 .. /*EAPG_Cnst.IDX_MAR*/12 LOOP
            NusiKbn_tbl[i] := lNusiKbn;
        END LOOP;

        -- 世帯主の存在チェック
        lNusiFlg := 0;
        FOR i IN /*EAPG_Cnst.IDX_APR1*/0 .. /*EAPG_Cnst.IDX_MAR*/12 LOOP
            IF NusiKbn_tbl[i] != /*EAPG_Cnst.NUSIJ_NASI*/0 THEN
                lNusiFlg := 1;
                EXIT;
            END IF;
        END LOOP;

        IF lNusiFlg = 0 THEN
            lErrMsg := '世帯主が存在しないため、作成対象外です。';
            PERFORM CCPG_BATCHWARNJOURNALWRITER$PRC_WriteWarn(lParam, /*THIS_PROC_BLOCK*/'加入状態作成', lErrMsg);

            pRet = /*RETURN_TRUE3*/3;
            RETURN;    -- 処理対象外
        END IF;

        -- ≪個人加入状態区分の設定≫
        -- 資格基準年月日時点での、資格対象構成員を抽出するカーソル
        DECLARE
            csrKouseiin CURSOR FOR
                SELECT T1.PersonNo
                     , T3.BYmd
                  -- @us 25/11/28 RG-EA-25-0071 各種一覧等のレスポンス改善
                  FROM (SELECT *
                          FROM EATB_Hihokensha
                         WHERE KokuhoNo  = pKokuhoNo
                           AND KokuhoRNo = pKokuhoRNo
                       ) T1
                       INNER JOIN EATB_SikakuTSRireki T2 ON  T1.KokuhoNo  = T2.KokuhoNo
                                                         AND T1.KokuhoRNo = T2.KokuhoRNo
                                                         AND T1.PersonNo  = T2.PersonNo
                       INNER JOIN CETB_PersonRireki   T3 ON  T1.PersonNo  = T3.PersonNo
                                                         AND T1.RirekiNo  = T3.RirekiNo
                  WHERE T2.TokuYmd <= pSikakuKijunYmd
                  -- @ue 25/11/28 RG-EA-25-0071
                    AND (   T2.SouYmd > pSikakuKijunYmd
                         OR makieya.isEmpty(T2.SouYmd) = TRUE )
                UNION
                SELECT T1.PersonNo
                     , T3.BYmd
                  -- @us 25/11/28 RG-EA-25-0071 各種一覧等のレスポンス改善
                  FROM (SELECT KokuhoNo
                             , PersonNo
                             , TokuteiKNo
                             , MAX(TokuteiRNo) TokuteiRNo
                          FROM EATB_TokuteishaRireki
                         WHERE KokuhoNo = pKokuhoNo
                           AND TorokuYmd <= pSikakuKijunYmd
                         GROUP BY KokuhoNo
                                , PersonNo
                                , TokuteiKNo) V1
                       INNER JOIN EATB_TokuteishaRireki T1 ON  V1.KokuhoNo    = T1.KokuhoNo
                                                           AND V1.PersonNo    = T1.PersonNo
                                                           AND V1.TokuteiKNo  = T1.TokuteiKNo
                                                           AND V1.TokuteiRNo  = T1.TokuteiRNo
                       INNER JOIN CETB_Person           T2 ON  T1.PersonNo    = T2.PersonNo
                       INNER JOIN CETB_PersonRireki     T3 ON  T2.PersonNo    = T3.PersonNo
                                                           AND T2.MaxRirekiNo = T3.RirekiNo
                 WHERE T1.TGaitoYmd <= pSikakuKijunYmd
                  -- @ue 25/11/28 RG-EA-25-0071
                   AND (T1.THigaitoYmd >= pSikakuKijunYmd
                     OR makieya.isEmpty(T1.THigaitoYmd) = TRUE )
                   AND T1.DelFlg = 0
                 ORDER BY PersonNo
                         ,BYmd;
        BEGIN
            pCnt := 1;
            EAPG_SichosonKisoFileT$KojinKanyuJ_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'KojinKanyuJ_', EAPG_SichosonKisoFileT$KojinKanyuJ_);
            FOR recKouseiin IN csrKouseiin LOOP

                -- 初期化
                FOR i IN /*EAPG_Cnst.IDX_APR1*/0 .. /*EAPG_Cnst.IDX_MAR*/12 LOOP
                    KojinKbn_tbl[i] := /*EAPG_Cnst.KOJINJ_NASI*/0;
                END LOOP;

                -- 資格得喪履歴テーブルより、得喪履歴情報を取得
                DECLARE
                    csrTSRireki CURSOR FOR
                        SELECT SikakuKbn
                             , TokuTdkYmd
                             , TokuYmd
                             , SouTdkYmd
                             , SouYmd
                             , SouJiyuCd
                          FROM EATB_SikakuTSRireki
                         WHERE KokuhoNo = pKokuhoNo
                           AND KokuhoRNo = pKokuhoRNo
                           AND PersonNo = recKouseiin.PersonNo
                           AND SikakuKbn <= /*EAPG_Cnst.SIKAKU_KAIGO*/3
                           AND TokuYmd <= pSikakuKijunYmd
                           AND (SouYmd > pSikakuKijunYmd
                            OR  makieya.isEmpty(SouYmd) = TRUE )
                         ORDER BY SikakuKbn
                                , TokuYmd;
                BEGIN
                    lKojinKbn := /*EAPG_Cnst.KOJINJ_NASI*/0;
                    FOR recTSRireki IN csrTSRireki LOOP

                        -- 適用終了日が入っていない場合
                        IF makieya.isEmpty(recTSRireki.SouYmd) = TRUE  THEN
                            -- 月末において資格取得中なら、加入状態をセット
                            CASE recTSRireki.SikakuKbn
                                WHEN /*EAPG_Cnst.SIKAKU_KOKUHO*/1 THEN
                                    lKojinKbn := /*EAPG_Cnst.KOJINJ_IPPAN*/1;
                                WHEN /*EAPG_Cnst.SIKAKU_TAISHOKU*/2 THEN
                                    IF lKojinKbn = /*EAPG_Cnst.KOJINJ_IPPAN*/1 THEN
                                        lKojinKbn := /*EAPG_Cnst.KOJINJ_TAISHOKU*/2;
                                    END IF;
                                WHEN /*EAPG_Cnst.SIKAKU_KAIGO*/3 THEN
                                    IF lKojinKbn = /*EAPG_Cnst.KOJINJ_IPPAN*/1 THEN
                                        lKojinKbn := /*EAPG_Cnst.KOJINJ_IPP_KAIGO*/3;
                                    ELSE
                                        lKojinKbn := /*EAPG_Cnst.KOJINJ_TAI_KAIGO*/4;
                                    END IF;
                            END CASE;

                        -- 適用終了日が入っている場合
                        ELSE
                            -- 適用終了日が資格基準年月日の翌日の場合 → 終了事由が「社保加入」であれば、資格保有日は資格適用終了日の前々日まで
                            -- ※後期高齢加入（年齢到達）、後期高齢加入（障害認定）の場合も同様の処理を行う
                            IF recTSRireki.SouYmd = makieya.dateadd(pSikakuKijunYmd, 1) AND
                               recTSRireki.SouJiyuCd IN (/*JIYUCD_SKANYU*/32, /*JIYUCD_KKANYU*/35, /*JIYUCD_SNINTEI*/36) THEN
                                NULL;

                            ELSIF recTSRireki.TokuYmd <= pSikakuKijunYmd AND
                                  recTSRireki.SouYmd > pSikakuKijunYmd THEN
                                CASE recTSRireki.SikakuKbn
                                    WHEN /*EAPG_Cnst.SIKAKU_KOKUHO*/1 THEN
                                        lKojinKbn := /*EAPG_Cnst.KOJINJ_IPPAN*/1;
                                    WHEN /*EAPG_Cnst.SIKAKU_TAISHOKU*/2 THEN
                                        IF lKojinKbn = /*EAPG_Cnst.KOJINJ_IPPAN*/1 THEN
                                            lKojinKbn := /*EAPG_Cnst.KOJINJ_TAISHOKU*/2;
                                        END IF;
                                    WHEN /*EAPG_Cnst.SIKAKU_KAIGO*/3 THEN
                                        IF lKojinKbn = /*EAPG_Cnst.KOJINJ_IPPAN*/1 THEN
                                            lKojinKbn := /*EAPG_Cnst.KOJINJ_IPP_KAIGO*/3;
                                        ELSE
                                            lKojinKbn := /*EAPG_Cnst.KOJINJ_TAI_KAIGO*/4;
                                        END IF;
                                END CASE;
                            END IF;
                        END IF;
                    END LOOP;
                END;

                -- 個人区分を設定する
                FOR i IN /*EAPG_Cnst.IDX_APR1*/0 .. /*EAPG_Cnst.IDX_MAR*/12 LOOP
                    KojinKbn_tbl[i] := lKojinKbn;
                END LOOP;

                -- 特定同一世帯所属者情報を取得
                DECLARE
                    csrTokuteisha CURSOR FOR
                        SELECT TGaitoYmd
                             , THigaitoYmd
                          -- @us 25/11/28 RG-EA-25-0071 各種一覧等のレスポンス改善
                          FROM (SELECT KokuhoNo
                                     , PersonNo
                                     , TokuteiKNo
                                     , MAX(TokuteiRNo) TokuteiRNo
                                  FROM EATB_TokuteishaRireki
                                 WHERE KokuhoNo = pKokuhoNo
                                   AND PersonNo = recKouseiin.PersonNo
                                   AND TorokuYmd <= pSikakuKijunYmd
                                 GROUP BY KokuhoNo
                                        , PersonNo
                                        , TokuteiKNo) V1
                               INNER JOIN EATB_TokuteishaRireki T1
                                  ON V1.KokuhoNo   = T1.KokuhoNo
                                 AND V1.PersonNo   = T1.PersonNo
                                 AND V1.TokuteiKNo = T1.TokuteiKNo
                                 AND V1.TokuteiRNo = T1.TokuteiRNo
                         WHERE T1.TGaitoYmd <= pSikakuKijunYmd
                          -- @ue 25/11/28 RG-EA-25-0071
                           AND (T1.THigaitoYmd >= pSikakuKijunYmd
                             OR makieya.isEmpty(T1.THigaitoYmd) = TRUE )
                           AND T1.DelFlg = 0
                         ORDER BY T1.TGaitoYmd;
                BEGIN
                    FOR recTokuteisha IN csrTokuteisha LOOP
                        FOR i IN /*EAPG_Cnst.IDX_APR1*/0 .. /*EAPG_Cnst.IDX_MAR*/12 LOOP
                            KojinKbn_tbl[i] := /*EAPG_Cnst.KOJINJ_TOKUTEISHA*/9;

                            -- 世帯主であれば、擬制世帯主に変更する
                            IF pSetainusiNo = recKouseiin.PersonNo AND NusiKbn_tbl[i] = /*EAPG_Cnst.NUSIJ_FUNUSI*/1 THEN
                                NusiKbn_tbl[i] := /*EAPG_Cnst.NUSIJ_GINUSI*/2;
                            END IF;

                            -- 月初において非該当なら、加入状態をリセット
                            IF  recTokuteisha.THigaitoYmd < KijunYmd_tbl[i] THEN
                                KojinKbn_tbl[i] := /*EAPG_Cnst.KOJINJ_NASI*/0;
                            END IF;

                        END LOOP;
                    END LOOP;


                    -- 75歳判定
                    -- 年度途中に75歳に到達する場合は、特定同一世帯所属者とする
                    FOR i IN /*EAPG_Cnst.IDX_APR1*/0 .. /*EAPG_Cnst.IDX_MAR*/12 LOOP
                        IF (TO_CHAR(recKouseiin.BYmd,'MM/DD') != '02/29' AND makieya.Add_Months(recKouseiin.BYmd, 900)     < KijunYmd_tbl[i]) OR
                           (TO_CHAR(recKouseiin.BYmd,'MM/DD')  = '02/29' AND makieya.dateadd(makieya.Add_Months(recKouseiin.BYmd, 900), 1) < KijunYmd_tbl[i]) THEN
                            IF KojinKbn_tbl[i] > /*EAPG_Cnst.KOJINJ_NASI*/0       AND
                               KojinKbn_tbl[i] < /*EAPG_Cnst.KOJINJ_TOKUTEISHA*/9 THEN

                                -- 75歳到達が資格基準年月日以前の場合
                                IF (TO_CHAR(recKouseiin.BYmd,'MM/DD') != '02/29' AND makieya.Add_Months(recKouseiin.BYmd, 900)     <= pSikakuKijunYmd) OR
                                   (TO_CHAR(recKouseiin.BYmd,'MM/DD')  = '02/29' AND makieya.dateadd(makieya.Add_Months(recKouseiin.BYmd, 900), 1) <= pSikakuKijunYmd) THEN
                                    -- 個人区分を特定同一世帯所属者に設定する
                                    FOR i IN /*EAPG_Cnst.IDX_APR1*/0 .. /*EAPG_Cnst.IDX_MAR*/12 LOOP
                                        KojinKbn_tbl[i] := /*EAPG_Cnst.KOJINJ_TOKUTEISHA*/9;

                                        -- 世帯主であれば、擬制世帯主に変更する
                                        IF pSetainusiNo = recKouseiin.PersonNo AND NusiKbn_tbl[i] = /*EAPG_Cnst.NUSIJ_FUNUSI*/1 THEN
                                            NusiKbn_tbl[i] := /*EAPG_Cnst.NUSIJ_GINUSI*/2;
                                        END IF;
                                    END LOOP;
                                    EXIT;

                                -- 75歳到達が資格基準年月日以降の場合
                                ELSE
                                    KojinKbn_tbl[i] := /*EAPG_Cnst.KOJINJ_TOKUTEISHA*/9;
                                END IF;

                                -- 世帯主であれば、擬制世帯主に変更する
                                IF pSetainusiNo = recKouseiin.PersonNo AND NusiKbn_tbl[i] = /*EAPG_Cnst.NUSIJ_FUNUSI*/1 THEN
                                    NusiKbn_tbl[i] := /*EAPG_Cnst.NUSIJ_GINUSI*/2;
                                END IF;
                            END IF;
                        END IF;
                    END LOOP;

                    -- @as 17/01/27 RM-EA-16-0048
                    -- 本人宛名番号の生年月日を取得し、
                    -- 生年月日の前日の月 + 781の月初の日付（65歳到達日の翌月初）に変換する。
                    BEGIN
                        SELECT makieya.Trunc(makieya.Add_Months(makieya.dateadd(T3.BYmd, -1), 781), 'MM')
                          INTO STRICT lBymdHonnin
                          -- @us 25/11/28 RG-EA-25-0071 各種一覧等のレスポンス改善
                          FROM (SELECT *
                                  FROM EATB_TAISHOKU
                                 WHERE KokuhoNo  = pKokuhoNo
                                   AND KokuhoRNo = pKokuhoRNo
                                   AND PersonNo  = recKouseiin.PersonNo
                               ) T1
                               INNER JOIN CETB_PERSON       T2 ON  T1.HonninPersonNo = T2.PersonNo
                               INNER JOIN CETB_PERSONRIREKI T3 ON  T2.PersonNo       = T3.PersonNo
                                                               AND T2.MaxRirekiNo    = T3.RirekiNo
                         WHERE T1.GaitoKbn       = /*EAPG_Cnst.GKBN_GAITO*/1    -- 「1:該当」
                          -- @ue 25/11/28 RG-EA-25-0071
                           AND T1.HonninFuyoKbn  = /*EAPG_Cnst.HFKBN_FUYO*/2;   -- 「2:被扶養者」
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            -- 生年月日が取得できない場合、65歳判定が必ずFALSEになる日付を設定
                            lBymdHonnin := makieya.TO_DATE('9999/12/31', 'YYYY/MM/DD');
                    END;

                    -- 生年月日の前日の月 + 781の月初の日付（65歳到達日の翌月初）
                    lBymd := makieya.Trunc(makieya.Add_Months(makieya.dateadd(recKouseiin.BYmd, -1), 781), 'MM');

                    --65歳判定
                    --年度途中に65歳に到達する場合は、個人月別加入状態を「1:一般被保険者」に変更する。
                    FOR i IN /*EAPG_Cnst.IDX_APR1*/0 .. /*EAPG_Cnst.IDX_MAR*/12 LOOP
                        -- 生年月日の前日の月 + 781の月初の日付 + 780 ＜ 基準日（該当月）の1年後
                        -- ※加入状態が変更になるのは65歳到達の翌月初であるため、閏年の対応は不要
                        IF (lBymd        < makieya.Add_Months(KijunYmd_tbl[i], 12) OR
                            lBymdHonnin  < makieya.Add_Months(KijunYmd_tbl[i], 12)
                        ) THEN
                            -- 個人月別加入状態＝「2：退職被保険者」OR「4：退職被保険者（介護２号該当）」
                            IF KojinKbn_tbl[i] = /*EAPG_Cnst.KOJINJ_TAISHOKU*/2 OR
                               KojinKbn_tbl[i] = /*EAPG_Cnst.KOJINJ_TAI_KAIGO*/4 THEN

                               -- 個人月別加入状態に「1:一般被保険者」を設定する。
                               KojinKbn_tbl[i] := /*EAPG_Cnst.KOJINJ_IPPAN*/1;
                            END IF;
                        END IF;
                    END LOOP;
                    -- @ae 17/01/27 RM-EA-16-0048
                END;

                -- 資格の有無チェック
                lFlg := 0;
                FOR i IN /*EAPG_Cnst.IDX_APR1*/0 .. /*EAPG_Cnst.IDX_MAR*/12 LOOP
                    IF KojinKbn_tbl[i] != /*EAPG_Cnst.KOJINJ_NASI*/0 THEN
                        lFlg := 1;
                        EXIT;
                    END IF;
                END LOOP;

                IF lFlg > 0 THEN
                    -- 個人加入状態テーブル更新内容セット
                    item = EAPG_SichosonKisoFileT$KojinKanyuJ_[pCnt];
                    item.FukaNendo   := pFukaNendo;
                    item.KokuhoNo    := pKokuhoNo;
                    item.SetainusiNo := pSetainusiNo;
                    item.PersonNo    := recKouseiin.PersonNo;
                    item.Apr1        := KojinKbn_tbl[/*EAPG_Cnst.IDX_APR1*/0];
                    item.Apr         := KojinKbn_tbl[/*EAPG_Cnst.IDX_APR*/1];
                    item.May         := KojinKbn_tbl[/*EAPG_Cnst.IDX_MAY*/2];
                    item.Jun         := KojinKbn_tbl[/*EAPG_Cnst.IDX_JUN*/3];
                    item.Jul         := KojinKbn_tbl[/*EAPG_Cnst.IDX_JUL*/4];
                    item.Aug         := KojinKbn_tbl[/*EAPG_Cnst.IDX_AUG*/5];
                    item.Sep         := KojinKbn_tbl[/*EAPG_Cnst.IDX_SEP*/6];
                    item.Oct         := KojinKbn_tbl[/*EAPG_Cnst.IDX_OCT*/7];
                    item.Nov         := KojinKbn_tbl[/*EAPG_Cnst.IDX_NOV*/8];
                    item.Dec         := KojinKbn_tbl[/*EAPG_Cnst.IDX_DEC*/9];
                    item.Jan         := KojinKbn_tbl[/*EAPG_Cnst.IDX_JAN*/10];
                    item.Feb         := KojinKbn_tbl[/*EAPG_Cnst.IDX_FEB*/11];
                    item.Mar         := KojinKbn_tbl[/*EAPG_Cnst.IDX_MAR*/12];
                    EAPG_SichosonKisoFileT$KojinKanyuJ_[pCnt] = item;
                    pCnt := pCnt + 1;
                END IF;

                -- 被保険者数カウント
                FOR i IN /*EAPG_Cnst.IDX_APR1*/0 .. /*EAPG_Cnst.IDX_MAR*/12 LOOP
                    IF KojinKbn_tbl[i] > /*EAPG_Cnst.KOJINJ_NASI*/0       AND
                       KojinKbn_tbl[i] < /*EAPG_Cnst.KOJINJ_TOKUTEISHA*/9 THEN
                        Hihosu_tbl[i] := Hihosu_tbl[i] + 1;
                    END IF;
                END LOOP;
            END LOOP;
            PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'KojinKanyuJ_', EAPG_SichosonKisoFileT$KojinKanyuJ_);
        END;

        EAPG_SichosonKisoFileT$KojinKanyuJ_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'KojinKanyuJ_', EAPG_SichosonKisoFileT$KojinKanyuJ_);
        -- 被保険者がいない場合は、世帯主区分を世帯主以外に変更する
        FOR i IN /*EAPG_Cnst.IDX_APR1*/0 .. /*EAPG_Cnst.IDX_MAR*/12 LOOP
            IF NusiKbn_tbl[i] != /*EAPG_Cnst.NUSIJ_NASI*/0 AND Hihosu_tbl[i] = 0 THEN
                NusiKbn_tbl[i] := /*EAPG_Cnst.NUSIJ_NASI*/0;
                -- 個人加入状態テーブル
                item = EAPG_SichosonKisoFileT$KojinKanyuJ_[pCnt];
                FOR j IN 1 .. pCnt - 1 LOOP
                  CASE i
                      WHEN /*EAPG_Cnst.IDX_APR1*/0 THEN
                          item.Apr1 := /*EAPG_Cnst.KOJINJ_NASI*/0;
                      WHEN /*EAPG_Cnst.IDX_APR*/1 THEN
                          item.Apr  := /*EAPG_Cnst.KOJINJ_NASI*/0;
                      WHEN /*EAPG_Cnst.IDX_MAY*/2 THEN
                          item.May  := /*EAPG_Cnst.KOJINJ_NASI*/0;
                      WHEN /*EAPG_Cnst.IDX_JUN*/3 THEN
                          item.Jun  := /*EAPG_Cnst.KOJINJ_NASI*/0;
                      WHEN /*EAPG_Cnst.IDX_JUL*/4 THEN
                          item.Jul  := /*EAPG_Cnst.KOJINJ_NASI*/0;
                      WHEN /*EAPG_Cnst.IDX_AUG*/5 THEN
                          item.Aug  := /*EAPG_Cnst.KOJINJ_NASI*/0;
                      WHEN /*EAPG_Cnst.IDX_SEP*/6 THEN
                          item.Sep  := /*EAPG_Cnst.KOJINJ_NASI*/0;
                      WHEN /*EAPG_Cnst.IDX_OCT*/7 THEN
                          item.Oct  := /*EAPG_Cnst.KOJINJ_NASI*/0;
                      WHEN /*EAPG_Cnst.IDX_NOV*/8 THEN
                          item.Nov  := /*EAPG_Cnst.KOJINJ_NASI*/0;
                      WHEN /*EAPG_Cnst.IDX_DEC*/9 THEN
                          item.Dec  := /*EAPG_Cnst.KOJINJ_NASI*/0;
                      WHEN /*EAPG_Cnst.IDX_JAN*/10 THEN
                          item.Jan  := /*EAPG_Cnst.KOJINJ_NASI*/0;
                      WHEN /*EAPG_Cnst.IDX_FEB*/11 THEN
                          item.Feb  := /*EAPG_Cnst.KOJINJ_NASI*/0;
                      WHEN /*EAPG_Cnst.IDX_MAR*/12 THEN
                          item.Mar  := /*EAPG_Cnst.KOJINJ_NASI*/0;
                  END CASE;
                END LOOP;
                EAPG_SichosonKisoFileT$KojinKanyuJ_[pCnt] = item;
            END IF;
        END LOOP;
        PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'KojinKanyuJ_', EAPG_SichosonKisoFileT$KojinKanyuJ_);

        -- 世帯主の存在チェック
        lNusiFlg := 0;
        FOR i IN /*EAPG_Cnst.IDX_APR1*/0 .. /*EAPG_Cnst.IDX_MAR*/12 LOOP
            IF NusiKbn_tbl[i] != /*EAPG_Cnst.NUSIJ_NASI*/0 THEN
                lNusiFlg := 1;
                EXIT;
            END IF;
        END LOOP;

        IF lNusiFlg = 0 THEN
            lErrMsg := '世帯主が存在しないため、作成対象外です。';
            PERFORM CCPG_BATCHWARNJOURNALWRITER$PRC_WriteWarn(lParam, /*THIS_PROC_BLOCK*/'加入状態作成', lErrMsg);

            pRet = /*RETURN_TRUE3*/3;
            RETURN;    -- 処理対象外
        END IF;

        -- 世帯主加入状態テーブル更新
        EAPG_SichosonKisoFileT$NusiKanyuJ_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'NusiKanyuJ_', EAPG_SichosonKisoFileT$NusiKanyuJ_);
        EAPG_SichosonKisoFileT$NusiKanyuJ_.FukaNendo   := pFukaNendo;
        EAPG_SichosonKisoFileT$NusiKanyuJ_.KokuhoNo    := pKokuhoNo;
        EAPG_SichosonKisoFileT$NusiKanyuJ_.SetainusiNo := pSetainusiNo;
        EAPG_SichosonKisoFileT$NusiKanyuJ_.Apr1        := NusiKbn_tbl[/*EAPG_Cnst.IDX_APR1*/0];
        EAPG_SichosonKisoFileT$NusiKanyuJ_.Apr         := NusiKbn_tbl[/*EAPG_Cnst.IDX_APR*/1];
        EAPG_SichosonKisoFileT$NusiKanyuJ_.May         := NusiKbn_tbl[/*EAPG_Cnst.IDX_MAY*/2];
        EAPG_SichosonKisoFileT$NusiKanyuJ_.Jun         := NusiKbn_tbl[/*EAPG_Cnst.IDX_JUN*/3];
        EAPG_SichosonKisoFileT$NusiKanyuJ_.Jul         := NusiKbn_tbl[/*EAPG_Cnst.IDX_JUL*/4];
        EAPG_SichosonKisoFileT$NusiKanyuJ_.Aug         := NusiKbn_tbl[/*EAPG_Cnst.IDX_AUG*/5];
        EAPG_SichosonKisoFileT$NusiKanyuJ_.Sep         := NusiKbn_tbl[/*EAPG_Cnst.IDX_SEP*/6];
        EAPG_SichosonKisoFileT$NusiKanyuJ_.Oct         := NusiKbn_tbl[/*EAPG_Cnst.IDX_OCT*/7];
        EAPG_SichosonKisoFileT$NusiKanyuJ_.Nov         := NusiKbn_tbl[/*EAPG_Cnst.IDX_NOV*/8];
        EAPG_SichosonKisoFileT$NusiKanyuJ_.Dec         := NusiKbn_tbl[/*EAPG_Cnst.IDX_DEC*/9];
        EAPG_SichosonKisoFileT$NusiKanyuJ_.Jan         := NusiKbn_tbl[/*EAPG_Cnst.IDX_JAN*/10];
        EAPG_SichosonKisoFileT$NusiKanyuJ_.Feb         := NusiKbn_tbl[/*EAPG_Cnst.IDX_FEB*/11];
        EAPG_SichosonKisoFileT$NusiKanyuJ_.Mar         := NusiKbn_tbl[/*EAPG_Cnst.IDX_MAR*/12];
        PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'NusiKanyuJ_', EAPG_SichosonKisoFileT$NusiKanyuJ_);

        pRet = /*RETURN_TRUE*/0;
        RETURN;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS SQLCODE = RETURNED_SQLSTATE;
            lErrMsg := concat(/*THIS_PACKAGE*/'EAPG_SichosonKisoFileT' , '.NewSikakuFuka:' , SQLCODE , ' ' , SQLERRM , ' ');
            CALL CBPG_ERRLOG$PRC_Logging(lErrMsg);
            pRet = /*RETURN_FALSE*/1;
            RETURN;

    END;

$$ LANGUAGE plpgsql;

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    -- 所得資産台帳情報を取得します。
    -- %usage
    -- 賦課年度に対する前年度、もしくは現年度の所得情報を取得します。
    -- %param pFukaNendo      賦課年度
    -- %param pKankatuCd      管轄コード
    -- %param pPersonNo       宛名番号
    -- %param pShtkDRireki    所得情報
    -- %return 戻り値
    --     {*}  0 正常終了
    --     {*}  1 異常終了
    --     {*}  2 取得データ無し
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    CREATE OR REPLACE FUNCTION EAPG_SichosonKisoFileT$GetShtk(pFukaNendo   IN numeric,
                     pKankatuCd   IN numeric,
                     pPersonNo    IN numeric,
                     pShtkDRireki OUT EATB_ShtkDRireki,
    pRet OUT numeric)


AS $$

    DECLARE
        SQLCODE varchar;
        lErrMsg           varchar(1000);
        lFukaNendo        numeric;
        lKankatuCd        numeric;
        lSisanGassanKbn   numeric;
        lYukoNo           EATB_ShtkDRireki.PersonNo%TYPE;
        lKoteiInfoRNo     EATB_ShtkDRireki.KoteiInfoRNo%TYPE;
        lKoteiKojin       EATB_ShtkDRireki.KoteiKojin%TYPE;
        lKoteiKyoyu       EATB_ShtkDRireki.KoteiKyoyu%TYPE;
        lKoteiInfoRNoW    EATB_ShtkDRireki.KoteiInfoRNo%TYPE;
        lKoteiKojinW      EATB_ShtkDRireki.KoteiKojin%TYPE;
        lKoteiKyoyuW      EATB_ShtkDRireki.KoteiKyoyu%TYPE;
        -- @as 20/02/14 RM-EA-19-0002
        lParam            varchar(1000);
    BEGIN
        -- 賦課年度を設定
        lFukaNendo := pFukaNendo;        -- 現年度
        -- 管轄コードが未選択の場合、0(全市)を設定する
        IF pKankatuCd = -1 THEN
            lKankatuCd := 0;
        ELSE
            lKankatuCd := pKankatuCd;
        END IF;

        DECLARE
            -- 所得資産台帳履歴テーブルを抽出する
            csrShtk CURSOR FOR
                SELECT T1.*
                  -- @us 25/11/28 RG-EA-25-0071 各種一覧等のレスポンス改善
                  FROM (SELECT *
                          FROM EATB_ShtkDaicho
                         WHERE FukaNendo = lFukaNendo
                           AND PersonNo  = pPersonNo
                       ) T2
                       INNER JOIN EATB_ShtkDRireki T1
                          ON T2.FukaNendo  = T1.FukaNendo
                         AND T2.PersonNo   = T1.PersonNo
                         AND T2.MaxShtkRNo = T1.ShtkRNo
                  -- @ue 25/11/28 RG-EA-25-0071
                 ORDER BY T1.FukaNendo DESC;
            recShtk    record;

        BEGIN
            -- 所得資産情報取得
            FOR recShtk IN csrShtk LOOP
                pShtkDRireki := recShtk;
                -- 取得後、即処理脱出
                EXIT;
            END LOOP;

            -- 取得できなければ処理終了
            IF makieya.isEmpty(pShtkDRireki.Fukanendo) = TRUE  THEN
                pRet = /*RETURN_TRUE2*/2;
                RETURN;
            END IF;

            -- @as 20/02/14 RM-EA-19-0002
            -- 賦課計算照会区分が「2：未」の場合
            IF pShtkDRireki.FukaShokaiKbn = 2 THEN
                lParam  := concat('賦課年度:' , lFukaNendo , ',宛名番号:' , pPersonNo , ',所得資産履歴番号:' , pShtkDRireki.ShtkRNo);
                lErrMsg := '照会されていない所得情報が存在します。不足している所得情報を照会してください。';

                -- ジャーナルに警告メッセージを出力する
                PERFORM CCPG_BATCHWARNJOURNALWRITER$PRC_WriteWarn(lParam,/*THIS_PROC_BLOCK*/'所得資産情報取得',lErrMsg);

            END IF;
            -- @ae 20/02/14 RM-EA-19-0002
        END;

        BEGIN

            BEGIN
                -- 所得資産パラメータの取得
                SELECT SisanGassanKbn
                  INTO STRICT lSisanGassanKbn
                  FROM EATM_ShtkParm
                 WHERE FukaNendo = pFukaNendo
                   AND KankatuCd = lKankatuCd;

            -- 取得できなければ処理終了
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    pRet = /*RETURN_TRUE2*/2;
                    RETURN;
            END;

            -- 重複者の資産情報を合算する場合
            IF lSisanGassanKbn = /*SISANGASSAN_YES*/1 THEN
                -- 有効宛名番号を取得
                BEGIN
                    SELECT YukoNo
                      INTO STRICT lYukoNo
                      FROM CETB_Jufukusha
                     WHERE PersonNo = pPersonNo;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        lYukoNo := 0;
                END;

                IF lYukoNo > 0 THEN
                    lKoteiInfoRNo := 0;
                    lKoteiKojin   := 0;
                    lKoteiKyoyu   := 0;

                    -- 重複者テーブルより重複者の宛名番号を取得する
                    DECLARE
                        csrJufukusha CURSOR FOR
                            SELECT PersonNo
                              FROM CETB_Jufukusha
                             WHERE YukoNo = lYukoNo
                               ORDER BY PersonNo;
                    BEGIN
                        -- 宛名番号と紐づく最新の資産税額(個人)、資産税額(共有)を取得する
                        FOR rec IN csrJufukusha LOOP
                            BEGIN
                                -- 宛名番号分処理を繰り返す
                                SELECT T2.KoteiInfoRNo
                                      ,T2.SisanZeigakKojin
                                      ,T2.SisanZeigakKyoyu
                                  INTO STRICT lKoteiInfoRNoW
                                      ,lKoteiKojinW
                                      ,lKoteiKyoyuW
                                  -- @us 25/11/28 RG-EA-25-0071 各種一覧等のレスポンス改善
                                  FROM (SELECT *
                                          FROM EETB_KoteiInfo
                                         WHERE FukaNendo = lFukaNendo
                                           AND GimushaNo = rec.PersonNo
                                       ) T1
                                       INNER JOIN EETB_KoteiInfoRireki T2
                                          ON T1.FukaNendo       = T2.FukaNendo
                                         AND T1.GimushaNo       = T2.GimushaNo
                                         AND T1.MaxKoteiInfoRNo = T2.KoteiInfoRNo;
                                  -- @ue 25/11/28 RG-EA-25-0071
                            EXCEPTION
                                WHEN NO_DATA_FOUND THEN
                                    lKoteiInfoRNoW := 0;
                                    lKoteiKojinW   := 0;
                                    lKoteiKyoyuW   := 0;
                            END;

                            IF lKoteiInfoRNo = 0 THEN
                                lKoteiInfoRNo := lKoteiInfoRNoW;
                            END IF;
                            lKoteiKojin := lKoteiKojin + lKoteiKojinW;
                            lKoteiKyoyu := lKoteiKyoyu + lKoteiKyoyuW;
                        END LOOP;
                    END;
                -- 有効番号が取得できなかった場合、pPersonNoと紐づく最新の資産税額(個人)、資産税額(共有)を取得する。
                ELSE
                    BEGIN
                        SELECT T2.KoteiInfoRNo
                              ,T2.SisanZeigakKojin
                              ,T2.SisanZeigakKyoyu
                          INTO STRICT lKoteiInfoRNo
                              ,lKoteiKojin
                              ,lKoteiKyoyu
                          -- @us 25/11/28 RG-EA-25-0071 各種一覧等のレスポンス改善
                          FROM (SELECT *
                                  FROM EETB_KoteiInfo
                                 WHERE FukaNendo = lFukaNendo
                                   AND GimushaNo = pPersonNo
                               ) T1
                               INNER JOIN EETB_KoteiInfoRireki T2
                                  ON T1.FukaNendo       = T2.FukaNendo
                                 AND T1.GimushaNo       = T2.GimushaNo
                                 AND T1.MaxKoteiInfoRNo = T2.KoteiInfoRNo;
                          -- @ue 25/11/28 RG-EA-25-0071
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            lKoteiInfoRNo := 0;
                            lKoteiKojin   := 0;
                            lKoteiKyoyu   := 0;
                    END;
                END IF;
            -- 重複者の資産情報を合算しない場合
            -- pPersonNoと紐づく最新の資産税額(個人)、資産税額(共有)を取得する。
            ELSE
                BEGIN
                    SELECT T2.KoteiInfoRNo
                          ,T2.SisanZeigakKojin
                          ,T2.SisanZeigakKyoyu
                      INTO STRICT lKoteiInfoRNo
                          ,lKoteiKojin
                          ,lKoteiKyoyu
                      -- @us 25/11/28 RG-EA-25-0071 各種一覧等のレスポンス改善
                      FROM (SELECT *
                              FROM EETB_KoteiInfo
                             WHERE FukaNendo = lFukaNendo
                               AND GimushaNo = pPersonNo
                           ) T1
                           INNER JOIN EETB_KoteiInfoRireki T2
                              ON T1.FukaNendo       = T2.FukaNendo
                             AND T1.GimushaNo       = T2.GimushaNo
                             AND T1.MaxKoteiInfoRNo = T2.KoteiInfoRNo;
                      -- @ue 25/11/28 RG-EA-25-0071
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        lKoteiInfoRNo := 0;
                        lKoteiKojin   := 0;
                        lKoteiKyoyu   := 0;
                END;
            END IF;
        END;

        pShtkDRireki.KoteiKojin  := lKoteiKojin;
        pShtkDRireki.KoteiKyoyu  := lKoteiKyoyu;
        pShtkDRireki.KoteiGokei  := lKoteiKojin + lKoteiKyoyu;

        pRet = /*RETURN_TRUE*/0;
        RETURN;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS SQLCODE = RETURNED_SQLSTATE;
            lErrMsg := concat(/*THIS_PACKAGE*/'EAPG_SichosonKisoFileT' , '.GetShtk:' , SQLCODE , ' ' , SQLERRM , ' ');
            CALL CBPG_ERRLOG$PRC_Logging(lErrMsg);
            pRet = /*RETURN_FALSE*/1;
            RETURN;

    END;

$$ LANGUAGE plpgsql;

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    -- 金額をチェックします。
    -- %usage
    -- 金額項目の値が最大値を超えていないかチェックします。
    -- %param pKingaku        チェック金額
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    CREATE OR REPLACE PROCEDURE EAPG_SichosonKisoFileT$CheckKingaku(
        pKingaku    IN OUT numeric)


AS $$

    DECLARE
        BEGIN
        IF pKingaku > /*EAPG_Cnst.MAX_NUMBER*/99999999999 THEN
            pKingaku := /*EAPG_Cnst.MAX_NUMBER*/99999999999;
        END IF;

    END;

$$ LANGUAGE plpgsql;

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    -- 平等割額半額を再判定します。
    -- %usage
    -- 被保険者→特定同一世帯所属者がいた場合に、平等割額半額対象と
    -- なるかどうかを判定します。
    -- %param pKokuhoNo       国保番号
    -- %param pKokuhoRNo      国保履歴番号
    -- %param pSetainusiNo    世帯主番号
    -- %param pEndYmd         判定対象終了日
    -- %param pSikakuKijunYmd 資格基準年月日
    -- %param pBHHihoSu       被保険者数(平等割半額対象)
    -- %param pBHTokuteiSu    特定同一世帯所属者数(平等割半額対象)
    -- %param pKCnt           被保険者カウント
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    CREATE OR REPLACE FUNCTION EAPG_SichosonKisoFileT$BHSaiHantei(pKokuhoNo       IN  numeric,
                          pKokuhoRNo      IN  numeric,
                          pSetainusiNo    IN  numeric,
                          pEndYmd         IN  timestamp(0) without time zone,
                          pSikakuKijunYmd IN  timestamp(0) without time zone,
                          pBHHihoSu       OUT numeric,
                          pBHTokuteiSu    OUT numeric,
                          pKCnt           IN  numeric)


AS $$

    DECLARE
        EAPG_SichosonKisoFileT$FukaKoseiin_ EATB_FukaKoseiin[];
        EAPG_SichosonKisoFileT$FukaKeisanParm1_ EATM_FukaKeisanParm1%ROWTYPE;
        SQLCODE varchar;
        lHanteiYmd       timestamp(0) without time zone;
        lHanteiYmd2      timestamp(0) without time zone;
        lBYmd            timestamp(0) without time zone;
        lBYmd2           timestamp(0) without time zone;
        lBHHihoFlg       numeric(1);
        lBHTokuteiFlg    numeric(1);
        lPersonNo        numeric;
        lCnt             integer;
        lCnt2            integer;
        i                integer;
        lErrMsg          varchar(1000);
    BEGIN

        CALL CBPG_PkgVariable$Init();

        -- 一時テーブルの初期化

        PERFORM CBPG_PkgVariable$InitValue('EAPG_SichosonKisoFileT', 'FukaKoseiin_', EAPG_SichosonKisoFileT$FukaKoseiin_);

        PERFORM CBPG_PkgVariable$InitValue('EAPG_SichosonKisoFileT', 'FukaKeisanParm1_', EAPG_SichosonKisoFileT$FukaKeisanParm1_);


        pBHHihoSu    := 0;
        pBHTokuteiSu := 0;

        -- 平等割額半額判定区分＝1：75歳到達前の場合と同じ処理･･･年度内の75歳到達者については、予め減額する
        --
        -- 生年月日の75年後を取得
        EAPG_SichosonKisoFileT$FukaKoseiin_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'FukaKoseiin_', EAPG_SichosonKisoFileT$FukaKoseiin_);
        FOR i IN 1 .. pKCnt LOOP
            SELECT MAX(makieya.Add_Months(CASE TO_CHAR(T2.BYmd, 'MMDD') WHEN  '0229' THEN  makieya.dateadd(T2.BYmd, 1) ELSE  T2.BYmd END, 900))
              INTO STRICT lHanteiYmd2
              -- @us 25/11/28 RG-EA-25-0071 各種一覧等のレスポンス改善
              FROM (SELECT *
                      FROM EATB_Hihokensha
                     WHERE KokuhoNo  = pKokuhoNo
                       AND KokuhoRNo = pKokuhoRNo
                       AND PersonNo  = EAPG_SichosonKisoFileT$FukaKoseiin_[i].PersonNo
                   ) T3
                   INNER JOIN CETB_Person       T1 ON  T3.PersonNo    = T1.PersonNo
                   INNER JOIN CETB_PersonRireki T2 ON  T1.PersonNo    = T2.PersonNo
                                                   AND T1.MaxRirekiNo = T2.RirekiNo
             WHERE (T3.ISouYmd <= makieya.dateadd(makieya.Add_Months(CASE TO_CHAR(T2.BYmd, 'MMDD') WHEN  '0229' THEN  makieya.dateadd(T2.BYmd, 1) ELSE  T2.BYmd END, 900), 1)
              -- @ue 25/11/28 RG-EA-25-0071
                 OR makieya.isEmpty(T3.ISouYmd) = TRUE )
               AND makieya.Add_Months(CASE TO_CHAR(T2.BYmd, 'MMDD') WHEN  '0229' THEN  makieya.dateadd(T2.BYmd, 1) ELSE  T2.BYmd END, 900) < pEndYmd;

            -- 2月29日の場合は、判定年月日 - 1 を判定年月日とする。
            IF makieya.isEmpty(lHanteiYmd2) = FALSE   AND TO_CHAR(lHanteiYmd2, 'MMDD') = '0229' THEN
                lHanteiYmd2 := makieya.dateadd(lHanteiYmd2, -1);
            END IF;

            -- 最大の生年月日を取得
            IF makieya.isEmpty(lHanteiYmd) = TRUE  AND makieya.isEmpty(lHanteiYmd2) = FALSE   THEN
                lHanteiYmd := lHanteiYmd2;
            ELSIF makieya.isEmpty(lHanteiYmd) = FALSE   AND makieya.isEmpty(lHanteiYmd2) = FALSE   THEN
                IF lHanteiYmd < lHanteiYmd2 THEN
                    lHanteiYmd := lHanteiYmd2;
                END IF;
            END IF;
        END LOOP;

        -- 判定年月日を設定できなかった場合、特定者該当年月日を取得し、判定年月日に設定する。
        IF makieya.isEmpty(lHanteiYmd) = TRUE  THEN
            SELECT MAX(T1.TGaitoYmd)
              INTO STRICT lHanteiYmd
              -- @us 25/11/28 RG-EA-25-0071 各種一覧等のレスポンス改善
              FROM (SELECT KokuhoNo
                         , PersonNo
                         , TokuteiKNo
                         , MAX(TokuteiRNo) TokuteiRNo
                      FROM EATB_TokuteishaRireki
                     WHERE KokuhoNo   = pKokuhoNo
                       AND TorokuYmd <= pSikakuKijunYmd
                     GROUP BY KokuhoNo
                            , PersonNo
                            , TokuteiKNo) V1
                   INNER JOIN EATB_TokuteishaRireki T1
                      ON V1.KokuhoNo   = T1.KokuhoNo
                     AND V1.PersonNo   = T1.PersonNo
                     AND V1.TokuteiKNo = T1.TokuteiKNo
                     AND V1.TokuteiRNo = T1.TokuteiRNo
             WHERE T1.TGaitoYmd   <= makieya.dateadd(pEndYmd, -1)
              -- @ue 25/11/28 RG-EA-25-0071
               AND (T1.THigaitoYmd >= makieya.dateadd(pEndYmd, -1)
                 OR makieya.isEmpty(T1.THigaitoYmd) = TRUE )
               AND T1.DelFlg       = 0;
        END IF;

        IF makieya.isEmpty(lHanteiYmd) = FALSE   THEN
            -- 世帯構成員の取得
            FOR i IN 1 .. pKCnt LOOP
                -- 宛名番号、生年月日の取得
                SELECT T1.PersonNo
                     , T2.BYmd
                  INTO STRICT lPersonNo
                     , lBYmd
                  -- @us 25/11/28 RG-EA-25-0071 各種一覧等のレスポンス改善
                  FROM (SELECT *
                          FROM CETB_Person
                         WHERE PersonNo = EAPG_SichosonKisoFileT$FukaKoseiin_[i].PersonNo
                       ) T1
                       INNER JOIN CETB_PersonRireki T2
                          ON T1.PersonNo    = T2.PersonNo
                         AND T1.MaxRirekiNo = T2.RirekiNo;
                  -- @ue 25/11/28 RG-EA-25-0071

                lBHHihoFlg    := 0;
                lBHTokuteiFlg := 0;

                -- 資格得喪履歴確認
                SELECT COUNT(*)
                  INTO STRICT lCnt
                  FROM EATB_SikakuTSRireki
                 WHERE KokuhoNo  = pKokuhoNo
                   AND KokuhoRNo = pKokuhoRNo
                   AND PersonNo  = lPersonNo
                   AND SikakuKbn = /*EAPG_Cnst.SIKAKU_KOKUHO*/1
                   AND TokuYmd  <= lHanteiYmd
                   AND ((SouYmd  > lHanteiYmd
                         AND SouJiyuCd NOT IN (/*EAPG_Cnst.JIYU_SHAHOKANYU*/32, /*EAPG_Cnst.JIYU_KOREIKANYU*/35, /*EAPG_Cnst.JIYU_KOREIKANYU_S*/36))
                     OR (SouYmd  > makieya.dateadd(lHanteiYmd, 1)
                         AND SouJiyuCd IN (/*EAPG_Cnst.JIYU_SHAHOKANYU*/32, /*EAPG_Cnst.JIYU_KOREIKANYU*/35, /*EAPG_Cnst.JIYU_KOREIKANYU_S*/36))
                     OR  (makieya.isEmpty(SouYmd) = TRUE ));

                IF lCnt > 0 THEN
                    -- 賦課パラメータ１.平等割額半額判定区分 = 「1:75歳到達前」の場合
                    EAPG_SichosonKisoFileT$FukaKeisanParm1_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'FukaKeisanParm1_', EAPG_SichosonKisoFileT$FukaKeisanParm1_);
                    IF EAPG_SichosonKisoFileT$FukaKeisanParm1_.ByodoWrHHKbn = /*EAPG_Cnst.BYODOWRHH_BEFORE*/1 THEN
                        IF TO_CHAR(makieya.Add_Months(lBYmd, 900), 'MMDD') = '0229' THEN
                            lBYmd2 := makieya.dateadd(makieya.Add_Months(lBYmd, 900), -1);
                        ELSIF TO_CHAR(lBYmd, 'MMDD') = '0229' THEN
                            lBYmd2 := makieya.dateadd(makieya.Add_Months(lBYmd, 900), 1);
                        ELSE
                            lBYmd2 := makieya.Add_Months(lBYmd, 900);
                        END IF;

                        IF lBYmd2 > lHanteiYmd THEN
                            lBHHihoFlg := 1;
                        ELSE
                            lBHTokuteiFlg := 1;
                        END IF;
                    ELSE
                        lBHHihoFlg := 1;
                    END IF;

                ELSE
                    -- 特定同一世帯所属者情報確認
                    SELECT COUNT(*)
                      INTO STRICT lCnt2
                      -- @us 25/11/28 RG-EA-25-0071 各種一覧等のレスポンス改善
                      FROM (SELECT KokuhoNo
                                 , PersonNo
                                 , TokuteiKNo
                                 , MAX(TokuteiRNo) TokuteiRNo
                              FROM EATB_TokuteishaRireki
                             WHERE KokuhoNo   = pKokuhoNo
                               AND PersonNo   = lPersonNo
                               AND TorokuYmd <= pSikakuKijunYmd
                             GROUP BY KokuhoNo
                                    , PersonNo
                                    , TokuteiKNo) V1
                           INNER JOIN EATB_TokuteishaRireki T1
                              ON V1.KokuhoNo   = T1.KokuhoNo
                             AND V1.PersonNo   = T1.PersonNo
                             AND V1.TokuteiKNo = T1.TokuteiKNo
                             AND V1.TokuteiRNo = T1.TokuteiRNo
                     WHERE T1.TGaitoYmd   <= lHanteiYmd
                      -- @ue 25/11/28 RG-EA-25-0071
                       AND (T1.THigaitoYmd >= lHanteiYmd
                         OR makieya.isEmpty(T1.THigaitoYmd) = TRUE )
                       AND T1.SetainusiNo  = pSetainusiNo
                       AND T1.DelFlg       = 0;

                    IF lCnt2 > 0 THEN
                        lBHTokuteiFlg := 1;
                    END IF;
                END IF;

                -- 平等割額半額判定用 軽減判定時 被保険者数カウント
                IF lBHHihoFlg = 1 THEN
                    pBHHihoSu := pBHHihoSu + 1;
                END IF;

                -- 平等割額半額判定用 軽減判定時 特定同一世帯所属者数カウント
                IF lBHTokuteiFlg = 1 THEN
                    pBHTokuteiSu := pBHTokuteiSu + 1;
                END IF;
            END LOOP;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS SQLCODE = RETURNED_SQLSTATE;
            lErrMsg := concat(/*THIS_PACKAGE*/'EAPG_SichosonKisoFileT' , '.BHSaiHantei:' , SQLCODE , ' ' , SQLERRM , ' ');
            CALL CBPG_ERRLOG$PRC_Logging(lErrMsg);
            PERFORM makieya.RAISE_APPLICATION_ERROR('EA900',
                                    lErrMsg,
                                    TRUE);
    END;

$$ LANGUAGE plpgsql;

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    -- 賦課限度額控除後試算ワークの設定項目に初期値をセットします。
    -- %usage
    -- 賦課限度額控除後試算ワークの設定項目に初期値をセットします。
    -- %param pFukaGendoSisan  賦課限度額控除後試算情報
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    CREATE OR REPLACE PROCEDURE EAPG_SichosonKisoFileT$InitFukaGendoSisan(pFukaGendoSisan IN OUT EATW_FukaGendoSisan)


AS $$

    DECLARE
        EAPG_SichosonKisoFileT$KyuyoShtkSu integer;
    BEGIN

        CALL CBPG_PkgVariable$Init();

        -- 一時テーブルの初期化

        PERFORM CBPG_PkgVariable$InitValue('EAPG_SichosonKisoFileT', 'KyuyoShtkSu', EAPG_SichosonKisoFileT$KyuyoShtkSu);

        -- 賦課限度額控除後試算ワーク
        pFukaGendoSisan.ShtkTGak   := 0;
        pFukaGendoSisan.SisanTGak  := 0;
        pFukaGendoSisan.Hihosu     := 0;
        pFukaGendoSisan.ByodoHKbn  := /*EAPG_Cnst.BYODOH_HIGAITO*/2;
        pFukaGendoSisan.ShtkWr     := 0;
        pFukaGendoSisan.SisanWr    := 0;
        pFukaGendoSisan.KintoWr    := 0;
        pFukaGendoSisan.ByodoWr    := 0;
        pFukaGendoSisan.KintoWrKei := 0;
        pFukaGendoSisan.ByodoWrKei := 0;
        pFukaGendoSisan.SanteiGak  := 0;
        PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'KyuyoShtkSu'                , 0);          -- @a 21/06/04 RM-EA-20-0027

    END;

$$ LANGUAGE plpgsql;

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    -- 賦課計算を行います。
    -- %usage
    -- 処理日時点での取得資格状況をもとに、賦課試算を行います。
    -- %param pFukaNendo        賦課年度
    -- %param pKokuhoNo         国保番号
    -- %param pKokuhoRNo        国保履歴番号
    -- %param pSetainusiNo      世帯主番号
    -- %param pKeigenKbn        軽減区分
    -- %param pCnt              被保険者カウント
    -- %return 戻り値
    --     {*}  0 正常終了
    --     {*}  1 異常終了
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    CREATE OR REPLACE FUNCTION EAPG_SichosonKisoFileT$FukaSisan(pFukaNendo       IN     numeric,
                       pKankatuCd       IN     numeric,
                       pKokuhoNo        IN     numeric,
                       pKokuhoRNo       IN     numeric,
                       pSetainusiNo     IN     numeric,
                       pKeigenKbn       OUT    numeric,
                       pCnt             IN     numeric,
                       pRet             OUT    numeric)


AS $$

    DECLARE
        EAPG_SichosonKisoFileT$NusiKanyuJ_ EATB_NusikanyuJ%ROWTYPE;
        EAPG_SichosonKisoFileT$SichosonKisoFileParm_ EATM_SichosonKisoFileParm[];
        item EATW_FukaGendoSisan;
        item2 EAPG_SichosonKisoFileT$TY_Keigen_R;
        item1 EATB_FukaKoseiin;
        EAPG_SichosonKisoFileT$FukaKeisanParm1_ EATM_FukaKeisanParm1%ROWTYPE;
        EAPG_SichosonKisoFileT$KyuyoShtkSu integer;
        EAPG_SichosonKisoFileT$FukaGendoSisan2_ EATW_FukaGendoSisan[];
        lrec record;
        EAPG_SichosonKisoFileT$FukaGendoSisan_ EAPG_SichosonKisoFileT$TY_Sisan_T[];
        EAPG_SichosonKisoFileT$FukaGendoSisanT EAPG_SichosonKisoFileT$TY_Sisan_T;
        EAPG_SichosonKisoFileT$FukaGendoSisan_R EAPG_SichosonKisoFileT$TY_Sisan_R[];
        EAPG_SichosonKisoFileT$FukaGendoSisanR EAPG_SichosonKisoFileT$TY_Sisan_R;
        -- @a 22/04/15 RM-EA-22-0002 年度内に75歳到達になっても平等割額が軽減対象にならない
        EAPG_SichosonKisoFileT$FukaGendoSisanR2 EAPG_SichosonKisoFileT$TY_Sisan_R;
        EAPG_SichosonKisoFileT$FukaGendoSisan1_ EAPG_SichosonKisoFileT$TY_Sisan_T[];
        EAPG_SichosonKisoFileT$FukaGendoSisan1T EAPG_SichosonKisoFileT$TY_Sisan_T;
        EAPG_SichosonKisoFileT$FukaGendoSisan1_R EAPG_SichosonKisoFileT$TY_Sisan_R[];
        EAPG_SichosonKisoFileT$FukaGendoSisan1R EAPG_SichosonKisoFileT$TY_Sisan_R;
        EAPG_SichosonKisoFileT$FukaKoseiin_ EATB_FukaKoseiin[];
        EAPG_SichosonKisoFileT$Keigen_ EAPG_SichosonKisoFileT$TY_Keigen_R[];
        EAPG_SichosonKisoFileT$KojinKanyuJ_ EATB_KojinKanyuJ[];
        EAPG_SichosonKisoFileT$Write_Flg numeric[];
        SQLCODE varchar;
        NusiKbn_tbl      numeric[];
        KojinKbn_tbl     numeric[];
        KojinKbn2_tbl    numeric[];
        TokuteiSu_tbl    numeric[];
        TokuteiSu2_tbl   numeric[];
        TokuteiSu3_tbl   numeric[];
        KijunYmd_tbl     timestamp(0) without time zone[];
        lSitugyoshaShtk  EATB_SitugyoshaShtk%ROWTYPE;
        lKHSitugyoshaFlg numeric(1);
        lSitugyoshaFlg   numeric(1);
        lSitugyoshaFlg2  numeric(1);
        lSitugyoshaFlg3  numeric(1);
        lShtkDRireki     EATB_ShtkDRireki%ROWTYPE;
        lFukaDRireki     EATB_FukaDRireki%ROWTYPE;
        lNusiSinkokuKbn  EATB_FukaDRireki.SinkokuKbn%TYPE;
        lSinkokuKbn      EATB_FukaDRireki.SinkokuKbn%TYPE;
        lSinkokuSu       EATB_FukaJoho.Hihosu%TYPE;
        lNoShtkSu        EATB_FukaJoho.Hihosu%TYPE;
        lBHKeiHihoSu     EATB_FukaJoho.Hihosu%TYPE;
        lBHKeiTokuteiSu  EATB_FukaJoho.Hihosu%TYPE;
        lShtkKei         EATB_FukaJoho.ShtkTGak%TYPE;
        lShtkTGak        EATB_FukaJoho.ShtkTGak%TYPE;
        lSisanTGak       EATB_FukaJoho.SisanTGak%TYPE;
        lShtkWr          EATB_FukaJoho.ShtkWr%TYPE;
        lSisanWr         EATB_FukaJoho.SisanWr%TYPE;
        lKeigenKTKbn     EATB_KeigenRireki.KeigenKTKbn%TYPE;
        lHokenzeiShu     EATM_SICHOSONKISOFILEPARM.HokenzeiShu%TYPE;
        lPersonNo        numeric;
        lWork            numeric;
        lWorkG           numeric;
        lWorkT           numeric;
        lKeiHanteiTFlg   numeric(1);
        lGinusi_Toku_Flg numeric(1);
        lBHKeiHihoFlg    numeric(1);
        lBHKeiTokuteiFlg numeric(1);
        lGNusiFlg        numeric(1);
        lKeiHanteiIdx    integer;
        lLastNusiIdx     integer;
        lIdx             integer;
        lFlg             integer;
        lCnt             integer;
        lKCnt            integer;
        lRet             integer;
        i                integer;
        j                integer;
        l                integer;
        lErrMsg          varchar(1000);
        lBYmd            timestamp(0) without time zone;
        lSikakuKijunYmd  timestamp(0) without time zone;

        -- @as 21/06/04 RM-EA-20-0027
        lKyuyoShtkFlg    numeric(1);
        lAge             numeric(3);
        -- @ae 21/06/04 RM-EA-20-0027

    BEGIN

        CALL CBPG_PkgVariable$Init();

        -- 一時テーブルの初期化

        PERFORM CBPG_PkgVariable$InitValue('EAPG_SichosonKisoFileT', 'NusiKanyuJ_', EAPG_SichosonKisoFileT$NusiKanyuJ_);

        PERFORM CBPG_PkgVariable$InitValue('EAPG_SichosonKisoFileT', 'SichosonKisoFileParm_', EAPG_SichosonKisoFileT$SichosonKisoFileParm_);

        PERFORM CBPG_PkgVariable$InitValue('EAPG_SichosonKisoFileT', 'FukaKeisanParm1_', EAPG_SichosonKisoFileT$FukaKeisanParm1_);

        PERFORM CBPG_PkgVariable$InitValue('EAPG_SichosonKisoFileT', 'KyuyoShtkSu', EAPG_SichosonKisoFileT$KyuyoShtkSu);

        PERFORM CBPG_PkgVariable$InitValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan2_', EAPG_SichosonKisoFileT$FukaGendoSisan2_);

        PERFORM CBPG_PkgVariable$InitValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan_', EAPG_SichosonKisoFileT$FukaGendoSisan_);

        PERFORM CBPG_PkgVariable$InitValue('EAPG_SichosonKisoFileT', 'FukaKoseiin_', EAPG_SichosonKisoFileT$FukaKoseiin_);

        PERFORM CBPG_PkgVariable$InitValue('EAPG_SichosonKisoFileT', 'Keigen_', EAPG_SichosonKisoFileT$Keigen_);

        PERFORM CBPG_PkgVariable$InitValue('EAPG_SichosonKisoFileT', 'KojinKanyuJ_', EAPG_SichosonKisoFileT$KojinKanyuJ_);

        PERFORM CBPG_PkgVariable$InitValue('EAPG_SichosonKisoFileT', 'Write_Flg', EAPG_SichosonKisoFileT$Write_Flg);

        lSikakuKijunYmd                  := CBPG_DATE$FNC_GetCurrentYMD();

        -- 加入状態を判断する基準日
        KijunYmd_tbl[/*EAPG_Cnst.IDX_APR1*/0] := makieya.TO_DATE(concat(pFukaNendo , '/04/02'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_APR*/1]  := makieya.TO_DATE(concat(pFukaNendo , '/05/01'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_MAY*/2]  := makieya.TO_DATE(concat(pFukaNendo , '/06/01'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_JUN*/3]  := makieya.TO_DATE(concat(pFukaNendo , '/07/01'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_JUL*/4]  := makieya.TO_DATE(concat(pFukaNendo , '/08/01'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_AUG*/5]  := makieya.TO_DATE(concat(pFukaNendo , '/09/01'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_SEP*/6]  := makieya.TO_DATE(concat(pFukaNendo , '/10/01'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_OCT*/7]  := makieya.TO_DATE(concat(pFukaNendo , '/11/01'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_NOV*/8]  := makieya.TO_DATE(concat(pFukaNendo , '/12/01'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_DEC*/9]  := makieya.TO_DATE(concat(pFukaNendo + 1 , '/01/01'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_JAN*/10]  := makieya.TO_DATE(concat(pFukaNendo + 1 , '/02/01'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_FEB*/11]  := makieya.TO_DATE(concat(pFukaNendo + 1 , '/03/01'),'YYYY/MM/DD');
        KijunYmd_tbl[/*EAPG_Cnst.IDX_MAR*/12]  := makieya.TO_DATE(concat(pFukaNendo + 1 , '/04/01'),'YYYY/MM/DD');

        EAPG_SichosonKisoFileT$FukaGendoSisan2_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan2_', EAPG_SichosonKisoFileT$FukaGendoSisan2_);
        -- 賦課限度額控除後試算ワーク初期化
        -- @u 26/xx/xx RG-EA-25-0002 子ども・子育て支援金制度の創設対応（３次）
        FOR i IN /*EAPG_Cnst.UTIWAKE_G*/1 .. /*EAPG_Cnst.UTIWAKE_KD*/11 LOOP
            -- 賦課限度額控除後試算ワーク
            EAPG_SichosonKisoFileT$FukaGendoSisan2_[i] := NULL;
            item = EAPG_SichosonKisoFileT$FukaGendoSisan2_[i];
            item.FukaNendo   := pFukaNendo;
            item.KokuhoNo    := pKokuhoNo;
            item.SetainusiNo := pSetainusiNo;
            item.UtiwakeKbn  := i;
            CALL EAPG_SichosonKisoFileT$InitFukaGendoSisan(item);
            EAPG_SichosonKisoFileT$FukaGendoSisan2_[i] = item;
        END LOOP;
        PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan2_', EAPG_SichosonKisoFileT$FukaGendoSisan2_);

        -- 賦課構成員テーブル初期化
        PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'FukaKoseiin_' , ARRAY[]::EATB_FukaKoseiin[]);

        -- 世帯主が擬制世帯主であるかどうかの判定(擬制→個人加入状態なし)
        lGNusiFlg := 0;
        EAPG_SichosonKisoFileT$NusiKanyuJ_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'NusiKanyuJ_', EAPG_SichosonKisoFileT$NusiKanyuJ_);
        EAPG_SichosonKisoFileT$KojinKanyuJ_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'KojinKanyuJ_', EAPG_SichosonKisoFileT$KojinKanyuJ_);
        FOR i IN 1 .. pCnt LOOP
            IF EAPG_SichosonKisoFileT$KojinKanyuJ_[i].PersonNo = EAPG_SichosonKisoFileT$NusiKanyuJ_.SetainusiNo THEN
                lGNusiFlg := 1;
                EXIT;
            END IF;
        END LOOP;

        -- 擬制なら賦課構成員テーブルの配列(世帯主分)を追加
        IF lGNusiFlg = 0 THEN
            lKCnt := pCnt + 1;
        ELSE
            lKCnt := pCnt;
        END IF;

        -- 賦課構成員テーブル作成
        EAPG_SichosonKisoFileT$FukaKoseiin_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'FukaKoseiin_', EAPG_SichosonKisoFileT$FukaKoseiin_);
        FOR i IN 1 .. lKCnt LOOP
            IF i = pCnt + 1 THEN
                item1 = EAPG_SichosonKisoFileT$FukaKoseiin_[i];
                item1.PersonNo := EAPG_SichosonKisoFileT$NusiKanyuJ_.SetainusiNo;
                EAPG_SichosonKisoFileT$FukaKoseiin_[i] = item1;
            ELSE
                item1 = EAPG_SichosonKisoFileT$FukaKoseiin_[i];
                item1.PersonNo := EAPG_SichosonKisoFileT$KojinKanyuJ_[i].PersonNo;
                EAPG_SichosonKisoFileT$FukaKoseiin_[i] = item1;
            END IF;
        END LOOP;
        PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'FukaKoseiin_', EAPG_SichosonKisoFileT$FukaKoseiin_);

        -- 特定同一世帯所属者テーブルの初期化
        FOR i IN /*EAPG_Cnst.IDX_APR1*/0 .. /*IDX_MAX*/12 LOOP
            TokuteiSu_tbl[i] := 0;
            TokuteiSu2_tbl[i] := 0;
            TokuteiSu3_tbl[i] := 0;
        END LOOP;

        -- 申告区分等の初期化
        lNusiSinkokuKbn           := /*EAPG_Cnst.SINKOKUKBN_G*/'G';
        lSinkokuKbn               := /*EAPG_Cnst.SINKOKUKBN_G*/'G';
        lShtkKei                  := 0;
        lSinkokuSu                := 0;
        lNoShtkSu                 := 0;
        lBHKeiHihoSu              := 0;
        lBHKeiTokuteiSu           := 0;
        lFukaDRireki.Keihihosu    := 0;
        lFukaDRireki.KeiKijunShtk := 0;
        lGinusi_Toku_Flg          := 0;

        -- 世帯主加入状態の取得
        FOR i IN /*EAPG_Cnst.IDX_APR1*/0 .. /*EAPG_Cnst.IDX_MAR*/12 LOOP
           CASE i
              WHEN /*EAPG_Cnst.IDX_APR1*/0 THEN  -- ４/１
                  NusiKbn_tbl[i] := EAPG_SichosonKisoFileT$NusiKanyuJ_.Apr1;
              WHEN /*EAPG_Cnst.IDX_APR*/1 THEN   -- ４月
                  NusiKbn_tbl[i] := EAPG_SichosonKisoFileT$NusiKanyuJ_.Apr;
              WHEN /*EAPG_Cnst.IDX_MAY*/2 THEN   -- ５月
                  NusiKbn_tbl[i] := EAPG_SichosonKisoFileT$NusiKanyuJ_.May;
              WHEN /*EAPG_Cnst.IDX_JUN*/3 THEN   -- ６月
                  NusiKbn_tbl[i] := EAPG_SichosonKisoFileT$NusiKanyuJ_.Jun;
              WHEN /*EAPG_Cnst.IDX_JUL*/4 THEN   -- ７月
                  NusiKbn_tbl[i] := EAPG_SichosonKisoFileT$NusiKanyuJ_.Jul;
              WHEN /*EAPG_Cnst.IDX_AUG*/5 THEN   -- ８月
                  NusiKbn_tbl[i] := EAPG_SichosonKisoFileT$NusiKanyuJ_.Aug;
              WHEN /*EAPG_Cnst.IDX_SEP*/6 THEN   -- ９月
                  NusiKbn_tbl[i] := EAPG_SichosonKisoFileT$NusiKanyuJ_.Sep;
              WHEN /*EAPG_Cnst.IDX_OCT*/7 THEN   -- １０月
                  NusiKbn_tbl[i] := EAPG_SichosonKisoFileT$NusiKanyuJ_.Oct;
              WHEN /*EAPG_Cnst.IDX_NOV*/8 THEN   -- １１月
                  NusiKbn_tbl[i] := EAPG_SichosonKisoFileT$NusiKanyuJ_.Nov;
              WHEN /*EAPG_Cnst.IDX_DEC*/9 THEN   -- １２月
                  NusiKbn_tbl[i] := EAPG_SichosonKisoFileT$NusiKanyuJ_.Dec;
              WHEN /*EAPG_Cnst.IDX_JAN*/10 THEN   -- １月
                  NusiKbn_tbl[i] := EAPG_SichosonKisoFileT$NusiKanyuJ_.Jan;
              WHEN /*EAPG_Cnst.IDX_FEB*/11 THEN   -- ２月
                  NusiKbn_tbl[i] := EAPG_SichosonKisoFileT$NusiKanyuJ_.Feb;
              WHEN /*EAPG_Cnst.IDX_MAR*/12 THEN   -- ３月
                  NusiKbn_tbl[i] := EAPG_SichosonKisoFileT$NusiKanyuJ_.Mar;
           END CASE;
        END LOOP;

        -- 世帯主である最後の月を取得する（世帯主区分のセットも行う）
        lLastNusiIdx := /*EAPG_Cnst.IDX_MAR*/12;
        lFukaDRireki.NusiKbn := -1;
        FOR i IN REVERSE /*EAPG_Cnst.IDX_MAR*/12 .. /*EAPG_Cnst.IDX_APR1*/0 LOOP
            IF NusiKbn_tbl[i] != /*EAPG_Cnst.NUSIJ_NASI*/0 THEN
                lLastNusiIdx := i;
                lFukaDRireki.NusiKbn := NusiKbn_tbl[i];
                IF lFukaDRireki.NusiKbn = /*EAPG_Cnst.KEINUSIKBN_GINUSI_TOKU*/3 THEN
                    lFukaDRireki.NusiKbn := /*EAPG_Cnst.KEINUSIKBN_GINUSI*/2;
                END IF;
                EXIT;
            END IF;
        END LOOP;

        -- 軽減判定対象月の判断
        lKeiHanteiIdx := 0;
        FOR i IN /*EAPG_Cnst.IDX_APR1*/0 .. /*EAPG_Cnst.IDX_MAR*/12 LOOP
            IF NusiKbn_tbl[i] != /*EAPG_Cnst.NUSIJ_NASI*/0 THEN
                lKeiHanteiIdx := i;
                EXIT;
            END IF;
        END LOOP;

        -- 軽減判定時世帯主区分
        lFukaDRireki.KeiNusiKbn := NusiKbn_tbl[lKeiHanteiIdx];

        -- 世帯主以外の場合
        IF lFukaDRireki.KeiNusiKbn = /*EAPG_Cnst.NUSIJ_NASI*/0 THEN
            -- 軽減判定時世帯主区分に「-1:納税[付]義務がなくなった」を設定
            lFukaDRireki.KeiNusiKbn := /*EAPG_Cnst.KEINUSIKBN_NASI*/-1;
        END IF;

        -- 軽減基準所得、所得割対象額、資産割対象額、被保険者数、所得割額、資産割額の集計
        -- 世帯構成員の取得

        EAPG_SichosonKisoFileT$FukaKeisanParm1_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'FukaKeisanParm1_', EAPG_SichosonKisoFileT$FukaKeisanParm1_);
        EAPG_SichosonKisoFileT$SichosonKisoFileParm_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'SichosonKisoFileParm_', EAPG_SichosonKisoFileT$SichosonKisoFileParm_);
        FOR l IN 1 .. lKCnt LOOP
            -- 宛名番号、生年月日の取得
            EAPG_SichosonKisoFileT$FukaKoseiin_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'FukaKoseiin_', EAPG_SichosonKisoFileT$FukaKoseiin_);
            SELECT T1.PersonNo
                 , T2.BYmd
              INTO STRICT lPersonNo
                 , lBYmd
              -- @us 25/11/28 RG-EA-25-0071 各種一覧等のレスポンス改善
              FROM (SELECT *
                      FROM CETB_Person
                     WHERE PersonNo = EAPG_SichosonKisoFileT$FukaKoseiin_[l].PersonNo
                   ) T1
                   INNER JOIN CETB_PersonRireki T2
                      ON T1.PersonNo    = T2.PersonNo
                     AND T1.MaxRirekiNo = T2.RirekiNo;
              -- @ue 25/11/28 RG-EA-25-0071

            -- 個人加入状態の取得
            -- 擬制世帯主の場合
            IF EAPG_SichosonKisoFileT$FukaKoseiin_[l].PersonNo = pSetainusiNo AND lGNusiFlg = 0 THEN
                FOR i IN /*EAPG_Cnst.IDX_APR1*/0 .. /*EAPG_Cnst.IDX_MAR*/12 LOOP
                    KojinKbn_tbl[i] := /*EAPG_Cnst.KOJINJ_NASI*/0;
                END LOOP;
            ELSE
                EAPG_SichosonKisoFileT$KojinKanyuJ_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'KojinKanyuJ_', EAPG_SichosonKisoFileT$KojinKanyuJ_);
                FOR i IN /*EAPG_Cnst.IDX_APR1*/0 .. /*EAPG_Cnst.IDX_MAR*/12 LOOP
                    CASE i
                        WHEN /*EAPG_Cnst.IDX_APR1*/0 THEN  -- ４/１
                            KojinKbn_tbl[i] := EAPG_SichosonKisoFileT$KojinKanyuJ_[l].Apr1;
                        WHEN /*EAPG_Cnst.IDX_APR*/1 THEN   -- ４月
                            KojinKbn_tbl[i] := EAPG_SichosonKisoFileT$KojinKanyuJ_[l].Apr;
                        WHEN /*EAPG_Cnst.IDX_MAY*/2 THEN   -- ５月
                            KojinKbn_tbl[i] := EAPG_SichosonKisoFileT$KojinKanyuJ_[l].May;
                        WHEN /*EAPG_Cnst.IDX_JUN*/3 THEN   -- ６月
                            KojinKbn_tbl[i] := EAPG_SichosonKisoFileT$KojinKanyuJ_[l].Jun;
                        WHEN /*EAPG_Cnst.IDX_JUL*/4 THEN   -- ７月
                            KojinKbn_tbl[i] := EAPG_SichosonKisoFileT$KojinKanyuJ_[l].Jul;
                        WHEN /*EAPG_Cnst.IDX_AUG*/5 THEN   -- ８月
                            KojinKbn_tbl[i] := EAPG_SichosonKisoFileT$KojinKanyuJ_[l].Aug;
                        WHEN /*EAPG_Cnst.IDX_SEP*/6 THEN   -- ９月
                            KojinKbn_tbl[i] := EAPG_SichosonKisoFileT$KojinKanyuJ_[l].Sep;
                        WHEN /*EAPG_Cnst.IDX_OCT*/7 THEN   -- １０月
                            KojinKbn_tbl[i] := EAPG_SichosonKisoFileT$KojinKanyuJ_[l].Oct;
                        WHEN /*EAPG_Cnst.IDX_NOV*/8 THEN   -- １１月
                            KojinKbn_tbl[i] := EAPG_SichosonKisoFileT$KojinKanyuJ_[l].Nov;
                        WHEN /*EAPG_Cnst.IDX_DEC*/9 THEN   -- １２月
                            KojinKbn_tbl[i] := EAPG_SichosonKisoFileT$KojinKanyuJ_[l].Dec;
                        WHEN /*EAPG_Cnst.IDX_JAN*/10 THEN   -- １月
                            KojinKbn_tbl[i] := EAPG_SichosonKisoFileT$KojinKanyuJ_[l].Jan;
                        WHEN /*EAPG_Cnst.IDX_FEB*/11 THEN   -- ２月
                            KojinKbn_tbl[i] := EAPG_SichosonKisoFileT$KojinKanyuJ_[l].Feb;
                        WHEN /*EAPG_Cnst.IDX_MAR*/12 THEN   -- ３月
                            KojinKbn_tbl[i] := EAPG_SichosonKisoFileT$KojinKanyuJ_[l].Mar;
                    END CASE;
                END LOOP;
            END IF;

            lIdx := /*EAPG_Cnst.IDX_MAR*/12;

            -- 特定者資格該当年月日と特定者非該当年月日を参照して、対象月毎に5年以内、8年以内、8年経過(軽減判定対象外)の
            -- 判断を行い、5年以内の特定同一世帯所属者数と、6年以上8年以内の特定同一世帯所属者数もカウントする。
            -- 初期化
            lCnt := 0;
            FOR i IN /*EAPG_Cnst.IDX_APR1*/0 .. /*IDX_MAX*/12 LOOP
                KojinKbn2_tbl[i] := /*EAPG_Cnst.KOJINJ_NASI*/0;
            END LOOP;

            -- 年度内で該当している特定同一世帯所属者を抽出
            DECLARE
                csrTokuteisha CURSOR FOR
                    SELECT oracle.last_day(makieya.Add_Months(T2.TSikakuGaitoYmd, /*TOKU_KIKAN1*/59)) THigaitoYmd5
                         , oracle.last_day(makieya.Add_Months(T2.TSikakuGaitoYmd, /*TOKU_KIKAN2*/95)) THigaitoYmd8
                         , T2.THigaitoYmd
                      -- @us 25/11/28 RG-EA-25-0071 各種一覧等のレスポンス改善
                      FROM (SELECT *
                              FROM EATB_Tokuteisha
                             WHERE KokuhoNo = pKokuhoNo
                               AND PersonNo = EAPG_SichosonKisoFileT$FukaKoseiin_[l].PersonNo
                           ) T1
                           INNER JOIN EATB_TokuteishaRireki T2
                              ON T1.KokuhoNo      = T2.KokuhoNo
                             AND T1.PersonNo      = T2.PersonNo
                             AND T1.TokuteiKNo    = T2.TokuteiKNo
                             AND T1.MaxTokuteiRNo = T2.TokuteiRNo
                     WHERE T2.SetainusiNo   = pSetainusiNo
                      -- @ue 25/11/28 RG-EA-25-0071
                       AND T2.DelFlg        = 0
                       AND ((T2.THigaitoYmd >= makieya.to_date(concat(pFukaNendo , '0401')) AND
                             T2.THigaitoYmd <= makieya.to_date(concat(pFukaNendo + 1 , '0331')))
                          OR makieya.isEmpty(T2.THigaitoYmd)  = TRUE )
                     ORDER BY T2.TGaitoYmd DESC;
            BEGIN
                FOR rec IN csrTokuteisha LOOP
                    lCnt := lCnt + 1;
                    IF TO_CHAR(rec.THigaitoYmd8,'YYYYMMDD') >= concat(pFukaNendo , '0401') THEN
                    -- 4月1日で8年経過していない特定同一世帯所属者を抽出(軽減対象者)
                        FOR i IN REVERSE /*EAPG_Cnst.IDX_MAR*/12 .. /*EAPG_Cnst.IDX_APR1*/0 LOOP
                            IF KojinKbn_tbl[i] = /*EAPG_Cnst.KOJINJ_TOKUTEISHA*/9 THEN
                                IF (makieya.isEmpty(rec.THigaitoYmd) = TRUE  OR rec.THigaitoYmd8 <= rec.THigaitoYmd) AND
                                    rec.THigaitoYmd8 < makieya.dateadd(KijunYmd_tbl[i], -1) THEN
                                    -- 8年経過した月以降は平等割額軽減非対象
                                    KojinKbn2_tbl[i] := 3;
                                ELSIF (makieya.isEmpty(rec.THigaitoYmd) = TRUE  OR rec.THigaitoYmd5 <= rec.THigaitoYmd) AND
                                       rec.THigaitoYmd5 < makieya.dateadd(KijunYmd_tbl[i], -1) THEN
                                    -- 5年経過した月以降を1/4軽減対象者に設定
                                    KojinKbn2_tbl[i] := 2;
                                ELSE
                                    -- 半額軽減対象者に設定
                                    KojinKbn2_tbl[i] := 1;
                                END IF;
                            END IF;
                        END LOOP;
                    ELSE
                    -- 4月1日で8年経過している場合は軽減非対象者とする
                        FOR i IN REVERSE /*EAPG_Cnst.IDX_MAR*/12 .. /*EAPG_Cnst.IDX_APR1*/0 LOOP
                            IF KojinKbn_tbl[i] = /*EAPG_Cnst.KOJINJ_TOKUTEISHA*/9 THEN
                                -- 8年経過した月以降は平等割額軽減非対象
                                KojinKbn2_tbl[i] := 3;
                            END IF;
                        END LOOP;
                    END IF;
                END LOOP;

                IF lCnt = 0 THEN
                -- 特定同一世帯所属者情報がなかった場合
                -- (特定同一世帯所属者以外もしくは年度途中75歳到達者)
                    FOR i IN REVERSE /*EAPG_Cnst.IDX_MAR*/12 .. /*EAPG_Cnst.IDX_APR1*/0 LOOP
                        IF KojinKbn_tbl[i] = /*EAPG_Cnst.KOJINJ_TOKUTEISHA*/9 THEN
                            -- 特定同一世帯所属者該当月は半額軽減対象者に設定
                            KojinKbn2_tbl[i] := 1;
                        END IF;
                    END LOOP;
                END IF;
            END;

            -- 特定同一世帯所属者数カウント
            FOR i IN /*EAPG_Cnst.IDX_APR1*/0 .. /*IDX_MAX*/12 LOOP
                IF KojinKbn_tbl[i] = /*EAPG_Cnst.KOJINJ_TOKUTEISHA*/9 THEN
                    IF KojinKbn2_tbl[i] = 1 THEN
                        -- 5年以内の特定同一世帯所属者カウント
                        TokuteiSu_tbl[i] := TokuteiSu_tbl[i] + 1;
                    ELSIF KojinKbn2_tbl[i] = 2 THEN
                        -- 8年以内の特定同一世帯所属者カウント
                        TokuteiSu2_tbl[i] := TokuteiSu2_tbl[i] + 1;
                    ELSIF KojinKbn2_tbl[i] = 3 THEN
                        -- 8年経過の特定同一世帯所属者カウント
                        TokuteiSu3_tbl[i] := TokuteiSu3_tbl[i] + 1;
                    END IF;
                END IF;
            END LOOP;


            -- 軽減判定対象者かどうかの判断
            lKeiHanteiTFlg   := 0;
            lBHKeiHihoFlg    := 0;
            lBHKeiTokuteiFlg := 0;
            lKHSitugyoshaFlg := 0;
            -- @as 21/06/04 RM-EA-20-0027
            lKyuyoShtkFlg    := 0;
            lAge             := 0;
            -- @ae 21/06/04 RM-EA-20-0027

            IF lKeiHanteiIdx = /*EAPG_Cnst.IDX_APR1*/0 THEN
                IF KojinKbn_tbl[/*EAPG_Cnst.IDX_APR1*/0] != /*EAPG_Cnst.KOJINJ_NASI*/0 THEN
                    -- 軽減判定対象者フラグ
                    lKeiHanteiTFlg := 1;

                    -- 擬制世帯主かつ特定同一世帯所属者
                    IF lPersonNo = pSetainusiNo AND
                       KojinKbn_tbl[/*EAPG_Cnst.IDX_APR1*/0] = /*EAPG_Cnst.KOJINJ_TOKUTEISHA*/9 THEN
                        -- 擬制特定同一所属者数フラグ
                        lGinusi_Toku_Flg := 1;
                    END IF;

                    -- 平等割額半額判定用 軽減判定時 特定同一世帯所属者
                    IF KojinKbn_tbl[/*EAPG_Cnst.IDX_APR1*/0] = /*EAPG_Cnst.KOJINJ_TOKUTEISHA*/9 THEN
                        -- 平等割軽減特定同一所属者フラグ
                        lBHKeiTokuteiFlg := 1;
                    -- 平等割額半額判定用 軽減判定時 被保険者
                    ELSE
                        -- 資格得喪履歴確認
                        IF KojinKbn_tbl[/*EAPG_Cnst.IDX_APR1*/0] > /*EAPG_Cnst.KOJINJ_NASI*/0       AND
                           KojinKbn_tbl[/*EAPG_Cnst.IDX_APR1*/0] < /*EAPG_Cnst.KOJINJ_TOKUTEISHA*/9 THEN
                            -- 平等割軽減被保険者フラグ
                            lBHKeiHihoFlg := 1;
                        END IF;
                    END IF;

                    -- 非自発的失業者であるか
                    SELECT COUNT(*)
                      INTO STRICT lCnt
                      FROM EATB_SitugyoshaKanri
                     WHERE KokuhoNo      = pKokuhoNo
                       AND PersonNo      = lPersonNo
                       AND KeigenSYmd   <= lSikakuKijunYmd
                       AND KeigenEYmdFK  > lSikakuKijunYmd
                       AND TorokuYmd    <= lSikakuKijunYmd
                       AND DelFlg        = 0;

                    IF lCnt > 0 THEN
                        lKHSitugyoshaFlg := 1;
                    END IF;
                END IF;

            -- 4月1日（賦課期日）より後の場合は、納税[付]義務発生日に資格があるか
            ELSE
                -- 資格得喪履歴確認
                IF KojinKbn_tbl[lKeiHanteiIdx] > /*EAPG_Cnst.KOJINJ_NASI*/0       AND
                   KojinKbn_tbl[lKeiHanteiIdx] < /*EAPG_Cnst.KOJINJ_TOKUTEISHA*/9 THEN

                    lKeiHanteiTFlg := 1;
                    lBHKeiHihoFlg := 1;

                ELSE
                    -- 特定同一世帯所属者情報確認
                    IF KojinKbn_tbl[lKeiHanteiIdx] = /*EAPG_Cnst.KOJINJ_TOKUTEISHA*/9 THEN
                        lKeiHanteiTFlg := 1;
                        lBHKeiTokuteiFlg := 1;
                        -- 擬制世帯主かつ特定同一世帯所属者
                        IF lPersonNo = pSetainusiNo THEN
                            lGinusi_Toku_Flg := 1;
                        END IF;
                    END IF;
                END IF;

                -- 非自発的失業者であるか
                SELECT COUNT(*)
                  INTO STRICT lCnt
                  FROM EATB_SitugyoshaKanri
                 WHERE KokuhoNo      = pKokuhoNo
                   AND PersonNo      = lPersonNo
                   AND KeigenSYmd   <= lSikakuKijunYmd
                   AND KeigenEYmdFK  > lSikakuKijunYmd
                   AND TorokuYmd    <= lSikakuKijunYmd
                   AND DelFlg        = 0;

                IF lCnt > 0 THEN
                    lKHSitugyoshaFlg := 1;
                END IF;
            END IF;

            -- 軽減判定時被保険者数カウント
            IF lKeiHanteiTFlg = 1 THEN
                lFukaDRireki.KeiHihosu := lFukaDRireki.KeiHihosu + 1;
            END IF;

            -- 擬制世帯主も軽減判定対象者とする
            IF lPersonNo = pSetainusiNo THEN
                lKeiHanteiTFlg := 1;
            END IF;

            -- 平等割額半額判定用 軽減判定時 被保険者数カウント
            IF lBHKeiHihoFlg = 1 THEN
                lBHKeiHihoSu := lBHKeiHihoSu + 1;
            END IF;

            -- 平等割額半額判定用 軽減判定時 特定同一世帯所属者数カウント
            IF lBHKeiTokuteiFlg = 1 THEN
                lBHKeiTokuteiSu := lBHKeiTokuteiSu + 1;
            END IF;

            -- 所得･資産台帳取得
            lrec := EAPG_SichosonKisoFileT$GetShtk(pFukaNendo
                           ,pKankatuCd
                           ,lPersonNo
                           );
            lRet = lrec.pRet;
            lShtkDRireki = lrec.pshtkdrireki;

            -- 所得･資産台帳がある場合
            IF lRet = /*RETURN_TRUE*/0 THEN
                -- 非自発的失業者所得情報取得
                lSitugyoshaFlg3 := 0;

                BEGIN
                    SELECT *
                      INTO STRICT lSitugyoshaShtk
                      FROM EATB_SitugyoshaShtk
                     WHERE FukaNendo = lShtkDRireki.FukaNendo
                       AND PersonNo  = lPersonNo
                       AND ShtkRNo   = lShtkDRireki.ShtkRNo;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        lSitugyoshaShtk.FukaNendo    := lShtkDRireki.FukaNendo;
                        lSitugyoshaShtk.PersonNo     := lPersonNo;
                        lSitugyoshaShtk.ShtkRNo      := lShtkDRireki.ShtkRNo;
                        lSitugyoshaShtk.KyuyoShtk    := 0;
                        lSitugyoshaShtk.ShtkKei      := 0;
                        lSitugyoshaShtk.ShtkKeiKTG   := 0;
                        lSitugyoshaShtk.KijunSoShtk  := 0;
                        lSitugyoshaShtk.ShtkKeiHB    := 0;
                        lSitugyoshaShtk.KazeiShtk    := 0;
                        lSitugyoshaShtk.ShtkKeiKGH   := 0;
                        lSitugyoshaShtk.KeiKijunShtk := 0;
                        lSitugyoshaShtk.KyuyoShtkM   := 0;
                        lSitugyoshaShtk.KyuyoShtkKGH := 0;
                        lSitugyoshaFlg3              := 1;
                END;

                -- 世帯主の申告区分を保持しておく
                IF lShtkDRireki.PersonNo = pSetainusiNo THEN
                    IF makieya.isEmpty(lShtkDRireki.SinkokuKbn) = FALSE   THEN
                      lNusiSinkokuKbn := lShtkDRireki.SinkokuKbn;
                    END IF;
                -- 世帯主以外で所得が最も多い人の申告区分を保持しておく
                ELSE
                    IF lKeiHanteiTFlg = 1 THEN
                        IF lShtkDRireki.ShtkKeiKTG >= 0 THEN
                            IF lShtkDRireki.ShtkKeiKTG > lShtkKei THEN
                                lShtkKei := lShtkDRireki.ShtkKeiKTG;
                                lSinkokuKbn := lShtkDRireki.SinkokuKbn;
                            ELSIF lShtkDRireki.ShtkKeiKTG = lShtkKei THEN
                                IF lShtkDRireki.SinkokuKbn IN (/*EAPG_Cnst.SINKOKUKBN_A*/'A'
                                                              ,/*EAPG_Cnst.SINKOKUKBN_B*/'B'
                                                              ,/*EAPG_Cnst.SINKOKUKBN_C*/'C'
                                                              ,/*EAPG_Cnst.SINKOKUKBN_D*/'D'
                                                              ,/*EAPG_Cnst.SINKOKUKBN_E*/'E') AND
                                   lSinkokuKbn > lShtkDRireki.SinkokuKbn THEN
                                    lSinkokuKbn := lShtkDRireki.SinkokuKbn;
                                ELSIF lShtkDRireki.SinkokuKbn = /*EAPG_Cnst.SINKOKUKBN_h*/'h' THEN
                                    -- 被扶養者世帯申告設定区分

                                    IF EAPG_SichosonKisoFileT$FukaKeisanParm1_.FuyoSetaiSKbn IN (/*EAPG_Cnst.FUYOSETAI_D*/2, /*EAPG_Cnst.FUYOSETAI_E*/3) THEN
                                        IF lSinkokuKbn = /*EAPG_Cnst.SINKOKUKBN_G*/'G' THEN
                                            lSinkokuKbn := lShtkDRireki.SinkokuKbn;
                                        END IF;
                                    END IF;
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                END IF;

                -- 軽減判定対象者の場合のみ
                IF lKeiHanteiTFlg = 1 THEN
                    -- 申告者をカウントする
                    IF lShtkDRireki.SinkokuKbn IN (/*EAPG_Cnst.SINKOKUKBN_A*/'A'
                                                  ,/*EAPG_Cnst.SINKOKUKBN_B*/'B'
                                                  ,/*EAPG_Cnst.SINKOKUKBN_C*/'C'
                                                  ,/*EAPG_Cnst.SINKOKUKBN_D*/'D'
                                                  ,/*EAPG_Cnst.SINKOKUKBN_E*/'E') THEN
                        lSinkokuSu := lSinkokuSu + 1;
                    ELSIF lShtkDRireki.SinkokuKbn = /*EAPG_Cnst.SINKOKUKBN_h*/'h' THEN
                        -- 被扶養者世帯申告設定区分
                        IF EAPG_SichosonKisoFileT$FukaKeisanParm1_.FuyoSetaiSKbn IN (/*EAPG_Cnst.FUYOSETAI_D*/2, /*EAPG_Cnst.FUYOSETAI_E*/3) THEN
                            lSinkokuSu := lSinkokuSu + 1;
                        END IF;
                    END IF;

                    -- 所得情報がない人をカウントする
                    IF makieya.isEmpty(lShtkDRireki.SinkokuKbn) = TRUE  OR
                       lShtkDRireki.SinkokuKbn = /*EAPG_Cnst.SINKOKUKBN_G*/'G' THEN
                        lNoShtkSu := lNoShtkSu + 1;
                    END IF;

                    -- 軽減基準所得を加算する
                    lWork := lFukaDRireki.KeiKijunShtk + lShtkDRireki.KeiKijunShtk;
                    IF lKHSitugyoshaFlg = 1 THEN
                        lWork := lFukaDRireki.KeiKijunShtk + lSitugyoshaShtk.KeiKijunShtk;
                    END IF;
                    CALL EAPG_SichosonKisoFileT$CheckKingaku(lWork);
                    lFukaDRireki.KeiKijunShtk := lWork;

                    -- @as 21/06/04 RM-EA-20-0027
                    -- 給与所得者を判定する
                    -- 賦課年度が令和3年度以降の場合
                    IF pFukaNendo >= /*FUKANENDO_R03*/2021 THEN
                        -- 一般給与収入額の判定
                        IF lShtkDRireki.IppanKyuyoShunyu > EAPG_SichosonKisoFileT$FukaKeisanParm1_.KyuyoShtkshaKijungak THEN
                            lKyuyoShtkFlg := 1;
                        END IF;
                        -- 公的年金収入額の判定
                        IF lShtkDRireki.NenkinShunyu > 0 THEN
                            -- 賦課年度の前年の12月31日時点の年齢を算出
                            lAge := CBPG_DateUtils$FNC_GetAge(concat(pFukaNendo - 1 , '/12/31'), TO_CHAR(lBymd, 'YYYY/MM/DD'));
                            -- 65歳以上の場合
                            IF lAge >= 65 THEN
                                IF lShtkDRireki.NenkinShunyu > EAPG_SichosonKisoFileT$FukaKeisanParm1_.NenkinSikyukijungak65 THEN
                                    lKyuyoShtkFlg := 1;
                                END IF;
                            -- 65歳未満の場合
                            ELSE
                                IF lShtkDRireki.NenkinShunyu > EAPG_SichosonKisoFileT$FukaKeisanParm1_.NenkinSikyukijungak64 THEN
                                    lKyuyoShtkFlg := 1;
                                END IF;
                            END IF;
                        END IF;
                        -- 一般給与収入額、公的年金収入額のいずれかが条件に該当した場合
                        IF lKyuyoShtkFlg = 1 THEN
                            PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'KyuyoShtkSu' , CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'KyuyoShtkSu', EAPG_SichosonKisoFileT$KyuyoShtkSu) + 1);
                        END IF;
                    END IF;
                    -- @ae 21/06/04 RM-EA-20-0027
                END IF;

                -- 所得割額等を計算する
                -- 資格基準日時点において非自発的失業者であるか
                lSitugyoshaFlg := 0;

                SELECT COUNT(*)
                  INTO STRICT lCnt
                  FROM EATB_SitugyoshaKanri
                 WHERE KokuhoNo      = pKokuhoNo
                   AND PersonNo      = lPersonNo
                   AND KeigenSYmd   <= lSikakuKijunYmd
                   AND KeigenEYmdFK  > lSikakuKijunYmd
                   AND TorokuYmd    <= lSikakuKijunYmd
                   AND DelFlg        = 0;

                IF lCnt > 0 THEN
                    lSitugyoshaFlg := 1;
                END IF;

                EAPG_SichosonKisoFileT$FukaGendoSisan_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan_', EAPG_SichosonKisoFileT$FukaGendoSisan_);
                -- 月別処理（4月1日（賦課期日）、賦課情報テーブル用を含む）
                FOR j IN /*EAPG_Cnst.IDX_APR1*/0 .. /*IDX_MAX*/12 LOOP

                    -- 非自発的失業者であるか
                    lSitugyoshaFlg2 := 0;

                    IF lSitugyoshaFlg = 1 AND
                        lSitugyoshaFlg3 <> 1 THEN

                        SELECT COUNT(*)
                          INTO STRICT lCnt
                          FROM EATB_SitugyoshaKanri
                         WHERE KokuhoNo      = pKokuhoNo
                           AND PersonNo      = lPersonNo
                           AND KeigenSYmd   <= lSikakuKijunYmd
                           AND KeigenEYmdFK  > lSikakuKijunYmd
                           AND TorokuYmd    <= lSikakuKijunYmd
                           AND DelFlg        = 0;

                        IF lCnt > 0 THEN
                            lSitugyoshaFlg2 := 1;
                        END IF;
                    END IF;

                    -- 所得割額の算定基礎
                    CASE EAPG_SichosonKisoFileT$FukaKeisanParm1_.ShtkSantei
                        -- 「1:旧ただし書方式」の場合
                        WHEN /*EAPG_Cnst.SHTKWR_KYUTDS*/1 THEN
                            lShtkTGak := lShtkDRireki.KijunSoShtk;
                            IF lSitugyoshaFlg2 = 1 THEN
                                lShtkTGak := lSitugyoshaShtk.KijunSoShtk;
                            END IF;
                        -- 「2:本文方式」の場合
                        WHEN /*EAPG_Cnst.SHTKWR_HONBUN*/2 THEN
                            lShtkTGak := lShtkDRireki.KazeiShtk;
                            IF lSitugyoshaFlg2 = 1 THEN
                                lShtkTGak := lSitugyoshaShtk.KazeiShtk;
                            END IF;
                        -- 「3:市町村民税所得割方式」の場合
                        WHEN /*EAPG_Cnst.SHTKWR_CSHTKWR*/3 THEN
                            lShtkTGak := lShtkDRireki.CShtkWr;
                        -- 「4:市町村民税額方式」の場合
                        WHEN /*EAPG_Cnst.SHTKWR_CZEI*/4 THEN
                            lShtkTGak := lShtkDRireki.CShtkWr
                                       + lShtkDRireki.CKintoWr;
                        -- 「5:道府県民税額等方式」の場合
                        WHEN /*EAPG_Cnst.SHTKWR_JZEI*/5 THEN
                            lShtkTGak := lShtkDRireki.CShtkWr
                                       + lShtkDRireki.CKintoWr
                                       + lShtkDRireki.KShtkWr
                                       + lShtkDRireki.KKintoWr;
                    END CASE;

                    -- 固定資産税相当額
                    lSisanTGak := lShtkDRireki.KoteiGokei;

                    -- @u 26/xx/xx RG-EA-25-0002 子ども・子育て支援金制度の創設対応（３次）
                    FOR i IN /*EAPG_Cnst.UTIWAKE_IG*/2 .. /*EAPG_Cnst.UTIWAKE_KD*/11 LOOP
                        lFlg := 0;
                        CASE i
                            -- 医療分（合計）
                            WHEN /*EAPG_Cnst.UTIWAKE_IG*/2 THEN
                                IF KojinKbn_tbl[j] >= /*EAPG_Cnst.KOJINJ_IPPAN*/1     AND
                                   KojinKbn_tbl[j] <= /*EAPG_Cnst.KOJINJ_TAI_KAIGO*/4 THEN
                                    lFlg := 1;
                                END IF;
                                lHokenzeiShu := /*EAPG_Cnst.HOKENSHU_IRYO*/1;
                            -- 医療分（退職）
                            WHEN /*EAPG_Cnst.UTIWAKE_IT*/4 THEN
                                IF KojinKbn_tbl[j] = /*EAPG_Cnst.KOJINJ_TAISHOKU*/2  OR
                                   KojinKbn_tbl[j] = /*EAPG_Cnst.KOJINJ_TAI_KAIGO*/4 THEN
                                    lFlg := 1;
                                END IF;
                                lHokenzeiShu := /*EAPG_Cnst.HOKENSHU_IRYO*/1;
                            -- 支援金分（合計）
                            WHEN /*EAPG_Cnst.UTIWAKE_SG*/5 THEN
                                IF KojinKbn_tbl[j] >= /*EAPG_Cnst.KOJINJ_IPPAN*/1     AND
                                   KojinKbn_tbl[j] <= /*EAPG_Cnst.KOJINJ_TAI_KAIGO*/4 THEN
                                    lFlg := 1;
                                END IF;
                                lHokenzeiShu := /*EAPG_Cnst.HOKENSHU_SIEN*/2;
                            -- 支援金分（退職）
                            WHEN /*EAPG_Cnst.UTIWAKE_ST*/7 THEN
                                IF KojinKbn_tbl[j] = /*EAPG_Cnst.KOJINJ_TAISHOKU*/2  OR
                                   KojinKbn_tbl[j] = /*EAPG_Cnst.KOJINJ_TAI_KAIGO*/4 THEN
                                    lFlg := 1;
                                END IF;
                                lHokenzeiShu := /*EAPG_Cnst.HOKENSHU_SIEN*/2;
                            -- 介護分（合計）
                            WHEN /*EAPG_Cnst.UTIWAKE_KG*/8 THEN
                                IF KojinKbn_tbl[j] = /*EAPG_Cnst.KOJINJ_IPP_KAIGO*/3 OR
                                   KojinKbn_tbl[j] = /*EAPG_Cnst.KOJINJ_TAI_KAIGO*/4 THEN
                                    lFlg := 1;
                                END IF;
                                lHokenzeiShu := /*EAPG_Cnst.HOKENSHU_KAIGO*/3;
                            -- 介護分（退職）
                            WHEN /*EAPG_Cnst.UTIWAKE_KT*/10 THEN
                                IF KojinKbn_tbl[j] = /*EAPG_Cnst.KOJINJ_TAI_KAIGO*/4 THEN
                                    lFlg := 1;
                                END IF;
                                lHokenzeiShu := /*EAPG_Cnst.HOKENSHU_KAIGO*/3;
                            -- @as 26/xx/xx RG-EA-25-0002 子ども・子育て支援金制度の創設対応（３次）
                            -- 子ども分
                            WHEN /*EAPG_Cnst.UTIWAKE_KD*/11 THEN
                                -- 賦課年度が令和8年度以降の場合
                                IF pFukaNendo >= /*FUKANENDO_R08*/2026 THEN
                                    IF KojinKbn_tbl[j] >= /*EAPG_Cnst.KOJINJ_IPPAN*/1     AND
                                       KojinKbn_tbl[j] <= /*EAPG_Cnst.KOJINJ_TAI_KAIGO*/4 THEN
                                        lFlg := 1;
                                    END IF;
                                END IF;
                                    lHokenzeiShu := /*EAPG_Cnst.HOKENSHU_KODOMO*/4;
                            -- @as 26/xx/xx RG-EA-25-0002     
                            ELSE
                                NULL;
                        END CASE;

                        IF lFlg = 1 THEN
                            -- 所得割対象額
                            EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[i];
                            EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                            EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[j];
                            lWork := EAPG_SichosonKisoFileT$FukaGendoSisanR.ShtkTGak + lShtkTGak;
                            CALL EAPG_SichosonKisoFileT$CheckKingaku(lWork);
                            EAPG_SichosonKisoFileT$FukaGendoSisanR.ShtkTGak := lWork;
                            -- 資産割対象額
                            IF makieya.array_length(EAPG_SichosonKisoFileT$SichosonKisoFileParm_) = 0 THEN
                                RAISE using errcode = 'MKER1';
                            END IF;
                            IF EAPG_SichosonKisoFileT$SichosonKisoFileParm_[lHokenzeiShu].SisanWari > 0 THEN
                               lWork := EAPG_SichosonKisoFileT$FukaGendoSisanR.SisanTGak + lSisanTGak;
                               CALL EAPG_SichosonKisoFileT$CheckKingaku(lWork);
                               EAPG_SichosonKisoFileT$FukaGendoSisanR.SisanTGak := lWork;
                            END IF;

                            -- 被保険者数
                            EAPG_SichosonKisoFileT$FukaGendoSisanR.Hihosu := EAPG_SichosonKisoFileT$FukaGendoSisanR.Hihosu + 1;
                            -- 合計の場合のみ
                            -- @u 26/xx/xx RG-EA-25-0002 子ども・子育て支援金制度の創設対応（３次）
                            IF i IN (/*EAPG_Cnst.UTIWAKE_IG*/2, /*EAPG_Cnst.UTIWAKE_SG*/5, /*EAPG_Cnst.UTIWAKE_KG*/8, /*EAPG_Cnst.UTIWAKE_KD*/11) THEN
                               -- 所得割額の計算 … 被保険者1人毎に算出して合算する ・小数点以下切り捨て
                               IF lShtkTGak > 0 THEN
                                   lShtkWr := FLOOR((lShtkTGak * EAPG_SichosonKisoFileT$SichosonKisoFileParm_[lHokenzeiShu].ShtkWari)::float / 100);
                               ELSE
                                   lShtkWr := 0;
                               END IF;
                               lWork := EAPG_SichosonKisoFileT$FukaGendoSisanR.ShtkWr + lShtkWr;
                               CALL EAPG_SichosonKisoFileT$CheckKingaku(lWork);
                               EAPG_SichosonKisoFileT$FukaGendoSisanR.ShtkWr := lWork;
                               -- 資産割額の計算 … 被保険者1人毎に算出して合算する ・小数点以下切り捨て
                               IF lSisanTGak > 0 THEN
                                   lSisanWr := FLOOR((lSisanTGak * EAPG_SichosonKisoFileT$SichosonKisoFileParm_[lHokenzeiShu].SisanWari)::float / 100);
                               ELSE
                                   lSisanWr := 0;
                               END IF;
                               lWork := EAPG_SichosonKisoFileT$FukaGendoSisanR.SisanWr + lSisanWr;
                               CALL EAPG_SichosonKisoFileT$CheckKingaku(lWork);
                               EAPG_SichosonKisoFileT$FukaGendoSisanR.SisanWr := lWork;
                            END IF;
                            EAPG_SichosonKisoFileT$FukaGendoSisan_R[j] := EAPG_SichosonKisoFileT$FukaGendoSisanR;
                            EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                            EAPG_SichosonKisoFileT$FukaGendoSisan_[i] := EAPG_SichosonKisoFileT$FukaGendoSisanT;
                        END IF;
                    END LOOP;
                END LOOP;

                PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan_', EAPG_SichosonKisoFileT$FukaGendoSisan_);
            -- 所得･資産台帳がない場合
            ELSIF lRet = /*RETURN_TRUE2*/2 THEN
                -- 軽減判定対象者の場合のみ
                IF lKeiHanteiTFlg = 1 THEN
                    -- 所得情報がない人をカウントする
                    lNoShtkSu := lNoShtkSu + 1;
                END IF;

                EAPG_SichosonKisoFileT$FukaGendoSisan_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan_', EAPG_SichosonKisoFileT$FukaGendoSisan_);

                -- 月別処理（4月1日（賦課期日））
                FOR j IN /*EAPG_Cnst.IDX_APR1*/0 .. /*IDX_MAX*/12 LOOP
                    -- @u 26/xx/xx RG-EA-25-0002 子ども・子育て支援金制度の創設対応（３次）
                    FOR i IN /*EAPG_Cnst.UTIWAKE_IG*/2 .. /*EAPG_Cnst.UTIWAKE_KD*/11 LOOP
                        lFlg := 0;
                        CASE i
                            -- 医療分（合計）
                            WHEN /*EAPG_Cnst.UTIWAKE_IG*/2 THEN
                                IF KojinKbn_tbl[j] >= /*EAPG_Cnst.KOJINJ_IPPAN*/1     AND
                                   KojinKbn_tbl[j] <= /*EAPG_Cnst.KOJINJ_TAI_KAIGO*/4 THEN
                                    lFlg := 1;
                                END IF;
                            -- 医療分（退職）
                            WHEN /*EAPG_Cnst.UTIWAKE_IT*/4 THEN
                                IF KojinKbn_tbl[j] = /*EAPG_Cnst.KOJINJ_TAISHOKU*/2  OR
                                   KojinKbn_tbl[j] = /*EAPG_Cnst.KOJINJ_TAI_KAIGO*/4 THEN
                                    lFlg := 1;
                                END IF;
                            -- 支援金分（合計）
                            WHEN /*EAPG_Cnst.UTIWAKE_SG*/5 THEN
                                IF KojinKbn_tbl[j] >= /*EAPG_Cnst.KOJINJ_IPPAN*/1     AND
                                   KojinKbn_tbl[j] <= /*EAPG_Cnst.KOJINJ_TAI_KAIGO*/4 THEN
                                    lFlg := 1;
                                END IF;
                            -- 支援金分（退職）
                            WHEN /*EAPG_Cnst.UTIWAKE_ST*/7 THEN
                                IF KojinKbn_tbl[j] = /*EAPG_Cnst.KOJINJ_TAISHOKU*/2  OR
                                   KojinKbn_tbl[j] = /*EAPG_Cnst.KOJINJ_TAI_KAIGO*/4 THEN
                                    lFlg := 1;
                                END IF;
                            -- 介護分（合計）
                            WHEN /*EAPG_Cnst.UTIWAKE_KG*/8 THEN
                                IF KojinKbn_tbl[j] = /*EAPG_Cnst.KOJINJ_IPP_KAIGO*/3 OR
                                   KojinKbn_tbl[j] = /*EAPG_Cnst.KOJINJ_TAI_KAIGO*/4 THEN
                                    lFlg := 1;
                                END IF;
                            -- 介護分（退職）
                            WHEN /*EAPG_Cnst.UTIWAKE_KT*/10 THEN
                                IF KojinKbn_tbl[j] = /*EAPG_Cnst.KOJINJ_TAI_KAIGO*/4 THEN
                                    lFlg := 1;
                                END IF;
                            -- @as 26/xx/xx RG-EA-25-0002 子ども・子育て支援金制度の創設対応（３次）
                            -- 子ども分
                            WHEN /*EAPG_Cnst.UTIWAKE_KD*/11 THEN
                                -- 賦課年度が令和8年度以降の場合
                                IF pFukaNendo >= /*FUKANENDO_R08*/2026 THEN
                                    IF KojinKbn_tbl[j] >= /*EAPG_Cnst.KOJINJ_IPPAN*/1     AND
                                       KojinKbn_tbl[j] <= /*EAPG_Cnst.KOJINJ_TAI_KAIGO*/4 THEN
                                        lFlg := 1;
                                    END IF;
                                END IF;
                                -- @as 26/xx/xx RG-EA-25-0002
                            ELSE
                                NULL;
                        END CASE;

                        IF lFlg = 1 THEN
                            EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[i];
                            EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                            EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[j];
                            -- 被保険者数
                            EAPG_SichosonKisoFileT$FukaGendoSisanR.Hihosu := EAPG_SichosonKisoFileT$FukaGendoSisanR.Hihosu + 1;
                            EAPG_SichosonKisoFileT$FukaGendoSisan_R[j] := EAPG_SichosonKisoFileT$FukaGendoSisanR;
                            EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                            EAPG_SichosonKisoFileT$FukaGendoSisan_[i] := EAPG_SichosonKisoFileT$FukaGendoSisanT;
                        END IF;
                    END LOOP;
                END LOOP;
                PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan_', EAPG_SichosonKisoFileT$FukaGendoSisan_);
            -- 所得情報取得処理エラーの場合
            ELSE
               pRet = /*RETURN_FALSE*/1;
               RETURN;
            END IF;
        END LOOP;

        -- 世帯の申告区分
        -- 初期値:所得不明
        lFukaDRireki.SinkokuKbn := /*EAPG_Cnst.SINKOKUKBN_G*/'G';
        -- ①世帯主の申告区分
        IF lNusiSinkokuKbn IN (/*EAPG_Cnst.SINKOKUKBN_A*/'A'
                              ,/*EAPG_Cnst.SINKOKUKBN_B*/'B'
                              ,/*EAPG_Cnst.SINKOKUKBN_C*/'C'
                              ,/*EAPG_Cnst.SINKOKUKBN_D*/'D'
                              ,/*EAPG_Cnst.SINKOKUKBN_E*/'E') THEN
            lFukaDRireki.SinkokuKbn := lNusiSinkokuKbn;
        -- ②所得が一番多い人の申告区分
        ELSIF lSinkokuKbn IN (/*EAPG_Cnst.SINKOKUKBN_A*/'A'
                             ,/*EAPG_Cnst.SINKOKUKBN_B*/'B'
                             ,/*EAPG_Cnst.SINKOKUKBN_C*/'C'
                             ,/*EAPG_Cnst.SINKOKUKBN_D*/'D'
                             ,/*EAPG_Cnst.SINKOKUKBN_E*/'E') THEN
            lFukaDRireki.SinkokuKbn := lSinkokuKbn;
        -- 被扶養者世帯申告設定区分
        ELSIF EAPG_SichosonKisoFileT$FukaKeisanParm1_.FuyoSetaiSKbn IN (/*EAPG_Cnst.FUYOSETAI_D*/2, /*EAPG_Cnst.FUYOSETAI_E*/3) THEN
            IF lNusiSinkokuKbn = /*EAPG_Cnst.SINKOKUKBN_h*/'h' OR
               lSinkokuKbn     = /*EAPG_Cnst.SINKOKUKBN_h*/'h' THEN
                IF EAPG_SichosonKisoFileT$FukaKeisanParm1_.FuyoSetaiSKbn = /*EAPG_Cnst.FUYOSETAI_D*/2 THEN
                    lFukaDRireki.SinkokuKbn := /*EAPG_Cnst.SINKOKUKBN_D*/'D';
                ELSE
                    lFukaDRireki.SinkokuKbn := /*EAPG_Cnst.SINKOKUKBN_E*/'E';
                END IF;

                IF lNusiSinkokuKbn = /*EAPG_Cnst.SINKOKUKBN_h*/'h' THEN
                    lNusiSinkokuKbn := lFukaDRireki.SinkokuKbn;
                END IF;
            END IF;
        END IF;

        -- 軽減対象世帯判定区分
        CASE EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeiSetaiHKbn
            -- 世帯構成員全員が申告している場合
            WHEN /*EAPG_Cnst.KEISETAIH_ALL*/1 THEN
                IF lNoShtkSu > 0  THEN
                    lFukaDRireki.SinkokuKbn := /*EAPG_Cnst.SINKOKUKBN_G*/'G';
                END IF;
            -- 世帯構成員が1人以上申告している場合
            WHEN /*EAPG_Cnst.KEISETAIH_ONE*/2 THEN
                IF lSinkokuSu = 0  THEN
                    lFukaDRireki.SinkokuKbn := /*EAPG_Cnst.SINKOKUKBN_G*/'G';
                END IF;
            -- 世帯主が申告している場合
            WHEN /*EAPG_Cnst.KEISETAIH_NUSI*/3 THEN
                IF lNusiSinkokuKbn NOT IN (/*EAPG_Cnst.SINKOKUKBN_A*/'A'
                                          ,/*EAPG_Cnst.SINKOKUKBN_B*/'B'
                                          ,/*EAPG_Cnst.SINKOKUKBN_C*/'C'
                                          ,/*EAPG_Cnst.SINKOKUKBN_D*/'D'
                                          ,/*EAPG_Cnst.SINKOKUKBN_E*/'E') THEN
                    lFukaDRireki.SinkokuKbn := /*EAPG_Cnst.SINKOKUKBN_G*/'G';
                END IF;
        END CASE;

        -- 軽減判定時世帯主区分
        -- 最終決定
        IF lGinusi_Toku_Flg = 1 THEN
            lFukaDRireki.KeiNusiKbn := /*EAPG_Cnst.KEINUSIKBN_GINUSI_TOKU*/3;
        END IF;

        -- 軽減判定区分
        -- @us 21/06/04 RM-EA-20-0027
        -- 賦課年度が令和2年以前の場合
        IF pFukaNendo < /*FUKANENDO_R03*/2021 THEN
            -- ①軽減基準所得が基礎控除額以下の世帯の場合
            IF lFukaDRireki.KeiKijunShtk <= EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeiKijunGak1 THEN
                lFukaDRireki.KeigenHKbn := EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeigenRitu1;
            -- ②賦課年度が平成26年以降で軽減基準所得が（基礎控除額＋被保険者数×政令で定める金額）以下の世帯の場合
            ELSIF lFukaDRireki.KeiKijunShtk <= EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeiKijunGak1 + lFukaDRireki.KeiHihosu * EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeiKijunGak2 THEN
                lFukaDRireki.KeigenHKbn := EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeigenRitu2;
            -- ③軽減基準所得が（基礎控除額＋被保険者数×軽減判定基準額3）以下の世帯の場合
            ELSIF lFukaDRireki.KeiKijunShtk <= EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeiKijunGak1 + lFukaDRireki.KeiHihosu * EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeiKijunGak3 THEN
                lFukaDRireki.KeigenHKbn := EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeigenRitu3;
            ELSE
                lFukaDRireki.KeigenHKbn := /*EAPG_Cnst.KEIGEN_NASI*/0;
            END IF;
        -- 賦課年度が令和3年以降の場合
        ELSE
            -- 給与所得者等の数が0以外の場合
            IF CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'KyuyoShtkSu', EAPG_SichosonKisoFileT$KyuyoShtkSu) > 0 THEN
                PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'KyuyoShtkSu' , CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'KyuyoShtkSu', EAPG_SichosonKisoFileT$KyuyoShtkSu) - 1);
            END IF;
            -- 軽減基準所得が（基礎控除額＋軽減基準調整額1×給与所得者数）以下の世帯の場合
            IF lFukaDRireki.KeiKijunShtk <= EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeiKijunGak1
                                             + EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeiKijunChoseiGak * CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'KyuyoShtkSu', EAPG_SichosonKisoFileT$KyuyoShtkSu) THEN
                lFukaDRireki.KeigenHKbn := EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeigenRitu1;
            -- 軽減基準所得が（基礎控除額＋軽減判定基準額2×軽減判定時被保険者数＋軽減基準調整額×給与所得者数）以下の世帯の場合
            ELSIF lFukaDRireki.KeiKijunShtk <= EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeiKijunGak1
                                                 + EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeiKijunGak2 * lFukaDRireki.KeiHihosu
                                                 + EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeiKijunChoseiGak * CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'KyuyoShtkSu', EAPG_SichosonKisoFileT$KyuyoShtkSu) THEN
                lFukaDRireki.KeigenHKbn := EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeigenRitu2;
            -- 軽減基準所得が（基礎控除額＋軽減判定基準額3×軽減判定時被保険者数＋軽減基準調整額×給与所得者数）以下の世帯の場合
            ELSIF lFukaDRireki.KeiKijunShtk <= EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeiKijunGak1
                                                 + EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeiKijunGak3 * lFukaDRireki.KeiHihosu
                                                 + EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeiKijunChoseiGak * CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'KyuyoShtkSu', EAPG_SichosonKisoFileT$KyuyoShtkSu) THEN
                lFukaDRireki.KeigenHKbn := EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeigenRitu3;
            -- 上記以外の場合
            ELSE
                lFukaDRireki.KeigenHKbn := /*EAPG_Cnst.KEIGEN_NASI*/0;
            END IF;
        END IF;
        -- @ue 21/02/26 RM-EA-20-0025
        -- 未申告の場合、軽減しない
        IF lFukaDRireki.SinkokuKbn = /*EAPG_Cnst.SINKOKUKBN_G*/'G' THEN
            lFukaDRireki.KeigenHKbn := /*EAPG_Cnst.KEIGEN_NASI*/0;
        END IF;

        -- 軽減強制適用区分の取得
        BEGIN
            SELECT T2.KeigenKTKbn
              INTO STRICT lKeigenKTKbn
              -- @us 25/11/28 RG-EA-25-0071 各種一覧等のレスポンス改善
              FROM (SELECT *
                      FROM EATB_KeigenKanri
                     WHERE FukaNendo   = pFukaNendo
                       AND KokuhoNo    = pKokuhoNo
                       AND SetainusiNo = pSetainusiNo
                   ) T1
                   INNER JOIN EATB_KeigenRireki T2
                      ON T1.FukaNendo    = T2.FukaNendo
                     AND T1.KokuhoNo     = T2.KokuhoNo
                     AND T1.SetainusiNo  = T2.SetainusiNo
                     AND T1.MaxKeigenRNo = T2.KeigenRNo;
              -- @ue 25/11/28 RG-EA-25-0071
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lKeigenKTKbn := /*EAPG_Cnst.KEIGENKT_NASI*/0;
        END;
        lFukaDRireki.KeigenKTKbn := lKeigenKTKbn;

        -- 軽減区分
        lFukaDRireki.KeigenKbn := lFukaDRireki.KeigenHKbn;

        -- 軽減区分セット
        pKeigenKbn := lFukaDRireki.KeigenKbn;

        EAPG_SichosonKisoFileT$Keigen_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'Keigen_', EAPG_SichosonKisoFileT$Keigen_);
        -- 均等割軽減額、平等割軽減額、平等割半額後軽減額算定
        -- @u 26/xx/xx RG-EA-25-0002 子ども・子育て支援金制度の創設対応（３次）
        FOR i IN /*EAPG_Cnst.HOKENSHU_IRYO*/1 .. /*EAPG_Cnst.HOKENSHU_KODOMO*/4 LOOP
            IF makieya.array_length(EAPG_SichosonKisoFileT$SichosonKisoFileParm_) = 0 THEN
                RAISE using errcode = 'MKER1';
            END IF;
            CASE lFukaDRireki.KeigenKbn
                WHEN EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeigenRitu1 THEN
                    item2 = EAPG_SichosonKisoFileT$Keigen_[i];
                    item2.KintoWrKei  := CEIL((EAPG_SichosonKisoFileT$SichosonKisoFileParm_[i].KintoWari       * EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeigenRitu1)::float / 10);
                    item2.ByodoWrKei  := CEIL((EAPG_SichosonKisoFileT$SichosonKisoFileParm_[i].ByodoWari       * EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeigenRitu1)::float / 10);
                    item2.ByodoWrHKei := CEIL(((EAPG_SichosonKisoFileT$SichosonKisoFileParm_[i].ByodoWari::float / 2) * EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeigenRitu1)::float / 10);
                    EAPG_SichosonKisoFileT$Keigen_[i] = item2;
                WHEN EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeigenRitu2 THEN
                    item2 = EAPG_SichosonKisoFileT$Keigen_[i];
                    item2.KintoWrKei  := CEIL((EAPG_SichosonKisoFileT$SichosonKisoFileParm_[i].KintoWari       * EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeigenRitu2)::float / 10);
                    item2.ByodoWrKei  := CEIL((EAPG_SichosonKisoFileT$SichosonKisoFileParm_[i].ByodoWari       * EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeigenRitu2)::float / 10);
                    item2.ByodoWrHKei := CEIL(((EAPG_SichosonKisoFileT$SichosonKisoFileParm_[i].ByodoWari::float / 2) * EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeigenRitu2)::float / 10);
                    EAPG_SichosonKisoFileT$Keigen_[i] = item2;
                WHEN EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeigenRitu3 THEN
                    item2 = EAPG_SichosonKisoFileT$Keigen_[i];
                    item2.KintoWrKei  := CEIL((EAPG_SichosonKisoFileT$SichosonKisoFileParm_[i].KintoWari       * EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeigenRitu3)::float / 10);
                    item2.ByodoWrKei  := CEIL((EAPG_SichosonKisoFileT$SichosonKisoFileParm_[i].ByodoWari       * EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeigenRitu3)::float / 10);
                    item2.ByodoWrHKei := CEIL(((EAPG_SichosonKisoFileT$SichosonKisoFileParm_[i].ByodoWari::float / 2) * EAPG_SichosonKisoFileT$FukaKeisanParm1_.KeigenRitu3)::float / 10);
                    EAPG_SichosonKisoFileT$Keigen_[i] = item2;
                ELSE
                    NULL;
            END CASE;
        END LOOP;
        PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'Keigen_', EAPG_SichosonKisoFileT$Keigen_);

        -- 賦課限度額控除後試算ワーク
        -- 世帯主でない月の場合、明細をクリアする
        EAPG_SichosonKisoFileT$FukaGendoSisan_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan_', EAPG_SichosonKisoFileT$FukaGendoSisan_);
        EAPG_SichosonKisoFileT$Write_Flg = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'Write_Flg', EAPG_SichosonKisoFileT$Write_Flg);
        -- @u 26/xx/xx RG-EA-25-0002 子ども・子育て支援金制度の創設対応（３次）
        FOR i IN /*EAPG_Cnst.UTIWAKE_G*/1 .. /*EAPG_Cnst.UTIWAKE_KD*/11 LOOP
            FOR j IN /*EAPG_Cnst.IDX_APR1*/0 .. /*EAPG_Cnst.IDX_MAR*/12 LOOP
                EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[i];
                EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[j];
                item := EAPG_SichosonKisoFileT$FukaGendoSisanR;
                IF NusiKbn_tbl[j] = /*EAPG_Cnst.NUSIJ_NASI*/0 THEN
                    CALL EAPG_SichosonKisoFileT$InitFukaGendoSisan(item);
                    TokuteiSu_tbl[j] := 0;
                    TokuteiSu2_tbl[j] := 0;
                    TokuteiSu3_tbl[j] := 0;
                END IF;
                EAPG_SichosonKisoFileT$FukaGendoSisanR := item;
                EAPG_SichosonKisoFileT$FukaGendoSisan_R[j] := EAPG_SichosonKisoFileT$FukaGendoSisanR;
                EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                EAPG_SichosonKisoFileT$FukaGendoSisan_[i] := EAPG_SichosonKisoFileT$FukaGendoSisanT;
            END LOOP;
            EAPG_SichosonKisoFileT$Write_Flg[i] := 0;
        END LOOP;

        PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan_' , EAPG_SichosonKisoFileT$FukaGendoSisan_);

        EAPG_SichosonKisoFileT$Write_Flg[/*EAPG_Cnst.UTIWAKE_G*/1] := 1;
        PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'Write_Flg', EAPG_SichosonKisoFileT$Write_Flg);
        -- 平等割額半額区分
        -- 被保険者数＝1かつ特定同一世帯所属者数＞0の場合、該当
        IF lKeiHanteiIdx = /*EAPG_Cnst.IDX_APR1*/0 THEN
            i := lKeiHanteiIdx + 1;
        ELSE
            i := lKeiHanteiIdx;
        END IF;

        EAPG_SichosonKisoFileT$FukaGendoSisan_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan_', EAPG_SichosonKisoFileT$FukaGendoSisan_);
        EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2];
        EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
        EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[lKeiHanteiIdx];

        IF lBHKeiHihoSu = 1 AND
           lBHKeiTokuteiSu > 0 AND
           EAPG_SichosonKisoFileT$FukaGendoSisanR.Hihosu > 0 THEN
            IF TokuteiSu_tbl[lKeiHanteiIdx] > 0 THEN

                EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2];
                EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[lKeiHanteiIdx];
                EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := /*EAPG_Cnst.BYODOH_GAITO*/1;
                EAPG_SichosonKisoFileT$FukaGendoSisan_R[lKeiHanteiIdx] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2] := EAPG_SichosonKisoFileT$FukaGendoSisanT;

                EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_SG*/5];
                EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[lKeiHanteiIdx];
                EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := /*EAPG_Cnst.BYODOH_GAITO*/1;
                EAPG_SichosonKisoFileT$FukaGendoSisan_R[lKeiHanteiIdx] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_SG*/5] := EAPG_SichosonKisoFileT$FukaGendoSisanT;

                -- @as 26/xx/xx RG-EA-25-0002 子ども・子育て支援金制度の創設対応（３次）
                EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_KD*/11];
                EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[lKeiHanteiIdx];
                EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := /*EAPG_Cnst.BYODOH_GAITO*/1;
                EAPG_SichosonKisoFileT$FukaGendoSisan_R[lKeiHanteiIdx] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_KD*/11] := EAPG_SichosonKisoFileT$FukaGendoSisanT;
                -- @ae 26/xx/xx RG-EA-25-0002

                EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2];
                EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*EAPG_Cnst.IDX_MAR*/12];
                EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := /*EAPG_Cnst.BYODOH_GAITO*/1;
                EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*EAPG_Cnst.IDX_MAR*/12] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2] := EAPG_SichosonKisoFileT$FukaGendoSisanT;

                EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_SG*/5];
                EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*EAPG_Cnst.IDX_MAR*/12];
                EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := /*EAPG_Cnst.BYODOH_GAITO*/1;
                EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*EAPG_Cnst.IDX_MAR*/12] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_SG*/5] := EAPG_SichosonKisoFileT$FukaGendoSisanT;

                -- @as 26/xx/xx RG-EA-25-0002 子ども・子育て支援金制度の創設対応（３次）
                EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_KD*/11];
                EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*EAPG_Cnst.IDX_MAR*/12];
                EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := /*EAPG_Cnst.BYODOH_GAITO*/1;
                EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*EAPG_Cnst.IDX_MAR*/12] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_KD*/11] := EAPG_SichosonKisoFileT$FukaGendoSisanT;
                -- @ae 26/xx/xx RG-EA-25-0002

            ELSIF TokuteiSu2_tbl[lKeiHanteiIdx] > 0 THEN

                EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2];
                EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[lKeiHanteiIdx];
                EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := /*EAPG_Cnst.BYODOH_GAITO2*/3;
                EAPG_SichosonKisoFileT$FukaGendoSisan_R[lKeiHanteiIdx] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2] := EAPG_SichosonKisoFileT$FukaGendoSisanT;

                EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_SG*/5];
                EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[lKeiHanteiIdx];
                EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := /*EAPG_Cnst.BYODOH_GAITO2*/3;
                EAPG_SichosonKisoFileT$FukaGendoSisan_R[lKeiHanteiIdx] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_SG*/5] := EAPG_SichosonKisoFileT$FukaGendoSisanT;

                -- @as 26/xx/xx RG-EA-25-0002 子ども・子育て支援金制度の創設対応（３次）
                EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_KD*/11];
                EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[lKeiHanteiIdx];
                EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := /*EAPG_Cnst.BYODOH_GAITO2*/3;
                EAPG_SichosonKisoFileT$FukaGendoSisan_R[lKeiHanteiIdx] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_KD*/11] := EAPG_SichosonKisoFileT$FukaGendoSisanT;
                -- @ae 26/xx/xx RG-EA-25-0002

                EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2];
                EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*EAPG_Cnst.IDX_MAR*/12];
                EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := /*EAPG_Cnst.BYODOH_GAITO2*/3;
                EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*EAPG_Cnst.IDX_MAR*/12] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2] := EAPG_SichosonKisoFileT$FukaGendoSisanT;

                EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_SG*/5];
                EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*EAPG_Cnst.IDX_MAR*/12];
                EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := /*EAPG_Cnst.BYODOH_GAITO2*/3;
                EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*EAPG_Cnst.IDX_MAR*/12] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_SG*/5] := EAPG_SichosonKisoFileT$FukaGendoSisanT;

                -- @as 26/xx/xx RG-EA-25-0002 子ども・子育て支援金制度の創設対応（３次）
                EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_KD*/11];
                EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*EAPG_Cnst.IDX_MAR*/12];
                EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := /*EAPG_Cnst.BYODOH_GAITO2*/3;
                EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*EAPG_Cnst.IDX_MAR*/12] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_KD*/11] := EAPG_SichosonKisoFileT$FukaGendoSisanT;
                -- @ae 26/xx/xx RG-EA-25-0002

            END IF;
            PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan_', EAPG_SichosonKisoFileT$FukaGendoSisan_);
        ELSE
            EAPG_SichosonKisoFileT$FukaGendoSisan_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan_', EAPG_SichosonKisoFileT$FukaGendoSisan_);
            EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2];
            EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
            -- @as 22/04/15 RM-EA-22-0002 年度内に75歳到達になっても平等割額が軽減対象にならない
            EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[j];
            EAPG_SichosonKisoFileT$FukaGendoSisanR2 := EAPG_SichosonKisoFileT$FukaGendoSisan_R[j - 1];
            -- @ae 22/04/15 RM-EA-22-0002
            FOR j IN i .. /*EAPG_Cnst.IDX_MAR*/12 LOOP
                IF TokuteiSu_tbl[j] + TokuteiSu2_tbl[j] > 0 AND
                   TokuteiSu_tbl[j - 1]  + TokuteiSu2_tbl[j - 1] < TokuteiSu_tbl[j]  + TokuteiSu2_tbl[j] THEN
                    -- @d 22/04/15 RM-EA-22-0002 年度内に75歳到達になっても平等割額が軽減対象にならない
                    lCnt :=  (TokuteiSu_tbl[j] + TokuteiSu2_tbl[j]) - (TokuteiSu_tbl[j - 1] + TokuteiSu2_tbl[j - 1]);
                    lBHKeiHihoSu    := EAPG_SichosonKisoFileT$FukaGendoSisanR.Hihosu + lCnt;
                    lBHKeiTokuteiSu := TokuteiSu_tbl[j] + TokuteiSu2_tbl[j] - lCnt;
                    i := j;
                    EXIT;
                -- @as 22/04/15 RM-EA-22-0002 年度内に75歳到達になっても平等割額が軽減対象にならない
                ELSIF TokuteiSu_tbl[j] + TokuteiSu2_tbl[j] > 0 AND
                   TokuteiSu_tbl[j - 1] + TokuteiSu2_tbl[j - 1] >= TokuteiSu_tbl[j] + TokuteiSu2_tbl[j]  AND
                   EAPG_SichosonKisoFileT$FukaGendoSisanR2.Hihosu > EAPG_SichosonKisoFileT$FukaGendoSisanR.Hihosu AND
                   TokuteiSu3_tbl[j - 1] < TokuteiSu3_tbl[j]  AND
                   EAPG_SichosonKisoFileT$FukaGendoSisanR.Hihosu = 1 THEN
                    lCnt :=  (TokuteiSu3_tbl[j] - TokuteiSu3_tbl[j - 1]);
                    lBHKeiHihoSu := EAPG_SichosonKisoFileT$FukaGendoSisanR.Hihosu + lCnt;
                    lBHKeiTokuteiSu := TokuteiSu_tbl[j] + TokuteiSu2_tbl[j] - lCnt;
                    i := j;
                    EXIT;
                -- @ae 22/04/15 RM-EA-22-0002
                END IF;
            END LOOP;
        END IF;

        EAPG_SichosonKisoFileT$FukaGendoSisan_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan_', EAPG_SichosonKisoFileT$FukaGendoSisan_);
        EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2];
        EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;

        FOR j IN i .. /*EAPG_Cnst.IDX_MAR*/12 LOOP
            EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[j];
            IF EAPG_SichosonKisoFileT$FukaGendoSisanR.Hihosu > 0 THEN
                -- 被保険者→特定同一世帯所属者がいる場合は再判定
                IF EAPG_SichosonKisoFileT$FukaGendoSisanR.Hihosu < lBHKeiHihoSu AND
                   TokuteiSu_tbl[j] + TokuteiSu2_tbl[j] > lBHKeiTokuteiSu THEN
                    EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*IDX_MAX*/12];
                    IF (NusiKbn_tbl[j - 1] = /*EAPG_CNST.NUSIJ_NASI*/0 OR
                       EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn = /*EAPG_Cnst.BYODOH_HIGAITO*/2) THEN
                        lrec = EAPG_SichosonKisoFileT$BHSaiHantei(pKokuhoNo
                                   ,pKokuhoRNo
                                   ,pSetainusiNo
                                   ,KijunYmd_tbl[j]
                                   ,lSikakuKijunYmd
                                   ,lKCnt);
                        lBHKeiHihoSu = lrec.pbhhihosu;
                        lBHKeiTokuteiSu = lrec.pbhtokuteisu;

                        IF lBHKeiHihoSu = 1 AND
                           lBHKeiTokuteiSu > 0 THEN

                            EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2];
                            EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                            EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[j];
                            EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := /*EAPG_Cnst.BYODOH_GAITO*/1;
                            EAPG_SichosonKisoFileT$FukaGendoSisan_R[j] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                            EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                            EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2] := EAPG_SichosonKisoFileT$FukaGendoSisanT;

                            EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_SG*/5];
                            EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                            EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[j];
                            EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := /*EAPG_Cnst.BYODOH_GAITO*/1;
                            EAPG_SichosonKisoFileT$FukaGendoSisan_R[j] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                            EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                            EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_SG*/5] := EAPG_SichosonKisoFileT$FukaGendoSisanT;

                            -- @as 26/xx/xx RG-EA-25-0002 子ども・子育て支援金制度の創設対応（３次）
                            EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_KD*/11];
                            EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                            EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[j];
                            EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := /*EAPG_Cnst.BYODOH_GAITO*/1;
                            EAPG_SichosonKisoFileT$FukaGendoSisan_R[j] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                            EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                            EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_KD*/11] := EAPG_SichosonKisoFileT$FukaGendoSisanT;
                            -- @ae 26/xx/xx RG-EA-25-0002

                            EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2];
                            EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                            EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*EAPG_Cnst.IDX_MAR*/12];
                            EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := /*EAPG_Cnst.BYODOH_GAITO*/1;
                            EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*EAPG_Cnst.IDX_MAR*/12] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                            EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                            EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2] := EAPG_SichosonKisoFileT$FukaGendoSisanT;

                            EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_SG*/5];
                            EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                            EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*EAPG_Cnst.IDX_MAR*/12];
                            EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := /*EAPG_Cnst.BYODOH_GAITO*/1;
                            EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*EAPG_Cnst.IDX_MAR*/12] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                            EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                            EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_SG*/5] := EAPG_SichosonKisoFileT$FukaGendoSisanT;

                            -- @as 26/xx/xx RG-EA-25-0002 子ども・子育て支援金制度の創設対応（３次）
                            EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_KD*/11];
                            EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                            EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*EAPG_Cnst.IDX_MAR*/12];
                            EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := /*EAPG_Cnst.BYODOH_GAITO*/1;
                            EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*EAPG_Cnst.IDX_MAR*/12] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                            EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                            EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_KD*/11] := EAPG_SichosonKisoFileT$FukaGendoSisanT;
                            -- @ae 26/xx/xx RG-EA-25-0002

                        END IF;
                    ELSE

                        EAPG_SichosonKisoFileT$FukaGendoSisan1T := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2];
                        EAPG_SichosonKisoFileT$FukaGendoSisan1_R := EAPG_SichosonKisoFileT$FukaGendoSisan1T.TIXSisan;
                        EAPG_SichosonKisoFileT$FukaGendoSisan1R := EAPG_SichosonKisoFileT$FukaGendoSisan1_R[/*IDX_MAX*/12];

                        EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2];
                        EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                        EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[j];
                        EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := EAPG_SichosonKisoFileT$FukaGendoSisan1R.ByodoHKbn;
                        EAPG_SichosonKisoFileT$FukaGendoSisan_R[j] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                        EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                        EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2] := EAPG_SichosonKisoFileT$FukaGendoSisanT;

                        EAPG_SichosonKisoFileT$FukaGendoSisan1T := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_SG*/5];
                        EAPG_SichosonKisoFileT$FukaGendoSisan1_R := EAPG_SichosonKisoFileT$FukaGendoSisan1T.TIXSisan;
                        EAPG_SichosonKisoFileT$FukaGendoSisan1R := EAPG_SichosonKisoFileT$FukaGendoSisan1_R[/*IDX_MAX*/12];

                        EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_SG*/5];
                        EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                        EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[j];
                        EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := EAPG_SichosonKisoFileT$FukaGendoSisan1R.ByodoHKbn;
                        EAPG_SichosonKisoFileT$FukaGendoSisan_R[j] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                        EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                        EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_SG*/5] := EAPG_SichosonKisoFileT$FukaGendoSisanT;

                        -- @as 26/xx/xx RG-EA-25-0002 子ども・子育て支援金制度の創設対応（３次）
                        EAPG_SichosonKisoFileT$FukaGendoSisan1T := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_KD*/11];
                        EAPG_SichosonKisoFileT$FukaGendoSisan1_R := EAPG_SichosonKisoFileT$FukaGendoSisan1T.TIXSisan;
                        EAPG_SichosonKisoFileT$FukaGendoSisan1R := EAPG_SichosonKisoFileT$FukaGendoSisan1_R[/*IDX_MAX*/12];

                        EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_KD*/11];
                        EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                        EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[j];
                        EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := EAPG_SichosonKisoFileT$FukaGendoSisan1R.ByodoHKbn;
                        EAPG_SichosonKisoFileT$FukaGendoSisan_R[j] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                        EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                        EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_KD*/11] := EAPG_SichosonKisoFileT$FukaGendoSisanT;
                        -- @ae 26/xx/xx RG-EA-25-0002

                    END IF;
                ELSE
                    EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2];
                    EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                    EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[j - 1];
                    IF EAPG_SichosonKisoFileT$FukaGendoSisanR.Hihosu > 0 THEN
                        lCnt := 0;
                        IF (TokuteiSu_tbl[j - 1] + TokuteiSu2_tbl[j - 1] + TokuteiSu3_tbl[j - 1]) > 0 AND
                           (TokuteiSu_tbl[j] + TokuteiSu2_tbl[j] + TokuteiSu3_tbl[j]) = 0 THEN
                            -- 月の途中で全部喪失していないか確認
                            SELECT COUNT(*)
                              INTO STRICT lCnt
                              -- @us 25/11/28 RG-EA-25-0071 各種一覧等のレスポンス改善
                              FROM (SELECT KokuhoNo
                                         , PersonNo
                                         , TokuteiKNo
                                         , MAX(TokuteiRNo) TokuteiRNo
                                      FROM EATB_TokuteishaRireki
                                     WHERE KokuhoNo   = pKokuhoNo
                                       AND TorokuYmd <= lSikakuKijunYmd
                                     GROUP BY KokuhoNo
                                            , PersonNo
                                            , TokuteiKNo) V1
                                   INNER JOIN EATB_TokuteishaRireki T1
                                      ON V1.KokuhoNo   = T1.KokuhoNo
                                     AND V1.PersonNo   = T1.PersonNo
                                     AND V1.TokuteiKNo = T1.TokuteiKNo
                                     AND V1.TokuteiRNo = T1.TokuteiRNo
                             WHERE T1.THigaitoYmd >= KijunYmd_tbl[j - 1]
                              -- @ue 25/11/28 RG-EA-25-0071
                               AND T1.THigaitoYmd  < makieya.dateadd(KijunYmd_tbl[j], -1)      -- @u 23/08/25 RM-EA-23-0011
                               AND T1.THigaitoKbn  = 4  -- 世帯全部喪失
                               AND T1.SetainusiNo  = pSetainusiNo
                               AND T1.DelFlg       = 0;
                        END IF;

                        IF lCnt = 0 THEN
                            EAPG_SichosonKisoFileT$FukaGendoSisan1T := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2];
                            EAPG_SichosonKisoFileT$FukaGendoSisan1_R := EAPG_SichosonKisoFileT$FukaGendoSisan1T.TIXSisan;
                            EAPG_SichosonKisoFileT$FukaGendoSisan1R := EAPG_SichosonKisoFileT$FukaGendoSisan1_R[j - 1];

                            EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2];
                            EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                            EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[j];
                            EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := EAPG_SichosonKisoFileT$FukaGendoSisan1R.ByodoHKbn;
                            EAPG_SichosonKisoFileT$FukaGendoSisan_R[j] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                            EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                            EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2] := EAPG_SichosonKisoFileT$FukaGendoSisanT;

                            EAPG_SichosonKisoFileT$FukaGendoSisan1T := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_SG*/5];
                            EAPG_SichosonKisoFileT$FukaGendoSisan1_R := EAPG_SichosonKisoFileT$FukaGendoSisan1T.TIXSisan;
                            EAPG_SichosonKisoFileT$FukaGendoSisan1R := EAPG_SichosonKisoFileT$FukaGendoSisan1_R[j - 1];

                            EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_SG*/5];
                            EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                            EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[j];
                            EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := EAPG_SichosonKisoFileT$FukaGendoSisan1R.ByodoHKbn;
                            EAPG_SichosonKisoFileT$FukaGendoSisan_R[j] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                            EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                            EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_SG*/5] := EAPG_SichosonKisoFileT$FukaGendoSisanT;
                            -- @as 26/xx/xx RG-EA-25-0002 子ども・子育て支援金制度の創設対応（３次）
                            EAPG_SichosonKisoFileT$FukaGendoSisan1T := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_KD*/11];
                            EAPG_SichosonKisoFileT$FukaGendoSisan1_R := EAPG_SichosonKisoFileT$FukaGendoSisan1T.TIXSisan;
                            EAPG_SichosonKisoFileT$FukaGendoSisan1R := EAPG_SichosonKisoFileT$FukaGendoSisan1_R[j - 1];

                            EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_KD*/11];
                            EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                            EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[j];
                            EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := EAPG_SichosonKisoFileT$FukaGendoSisan1R.ByodoHKbn;
                            EAPG_SichosonKisoFileT$FukaGendoSisan_R[j] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                            EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                            EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_KD*/11] := EAPG_SichosonKisoFileT$FukaGendoSisanT;
                            -- @ae 26/xx/xx RG-EA-25-0002
                        END IF;
                    END IF;
                END IF;
            END IF;
        END LOOP;

        EAPG_SichosonKisoFileT$FukaGendoSisan1T := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2];
        EAPG_SichosonKisoFileT$FukaGendoSisan1_R := EAPG_SichosonKisoFileT$FukaGendoSisan1T.TIXSisan;
        EAPG_SichosonKisoFileT$FukaGendoSisan1R := EAPG_SichosonKisoFileT$FukaGendoSisan1_R[lIdx];

        EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2];
        EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
        EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*IDX_MAX*/12];
        EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := EAPG_SichosonKisoFileT$FukaGendoSisan1R.ByodoHKbn;
        EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*IDX_MAX*/12] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
        EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
        EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_IG*/2] := EAPG_SichosonKisoFileT$FukaGendoSisanT;

        EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_SG*/5];
        EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
        EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*IDX_MAX*/12];
        EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := EAPG_SichosonKisoFileT$FukaGendoSisan1R.ByodoHKbn;
        EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*IDX_MAX*/12] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
        EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
        EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_SG*/5] := EAPG_SichosonKisoFileT$FukaGendoSisanT;

        -- @as 26/xx/xx RG-EA-25-0002 子ども・子育て支援金制度の創設対応（３次）
        EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_KD*/11];
        EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
        EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*IDX_MAX*/12];
        EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn := EAPG_SichosonKisoFileT$FukaGendoSisan1R.ByodoHKbn;
        EAPG_SichosonKisoFileT$FukaGendoSisan_R[/*IDX_MAX*/12] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
        EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
        EAPG_SichosonKisoFileT$FukaGendoSisan_[/*EAPG_Cnst.UTIWAKE_KD*/11] := EAPG_SichosonKisoFileT$FukaGendoSisanT;
        -- @ae 26/xx/xx RG-EA-25-0002

        EAPG_SichosonKisoFileT$Write_Flg = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'Write_Flg', EAPG_SichosonKisoFileT$Write_Flg);
        EAPG_SichosonKisoFileT$Keigen_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'Keigen_', EAPG_SichosonKisoFileT$Keigen_);
        -- 均等割額、平等割額、均等割軽減額、平等割軽減額の計算（合計分）
        -- @us 26/xx/xx RG-EA-25-0002 子ども・子育て支援金制度の創設対応（３次）
        FOR i IN /*EAPG_Cnst.UTIWAKE_IG*/2 .. /*EAPG_Cnst.UTIWAKE_KD*/11 LOOP
            -- 合計の場合
            IF i IN (/*EAPG_Cnst.UTIWAKE_IG*/2, /*EAPG_Cnst.UTIWAKE_SG*/5, /*EAPG_Cnst.UTIWAKE_KG*/8, /*EAPG_Cnst.UTIWAKE_KD*/11) THEN
                CASE i
                    WHEN /*EAPG_Cnst.UTIWAKE_IG*/2 THEN
                        lHokenzeiShu := /*EAPG_Cnst.HOKENSHU_IRYO*/1;
                    WHEN /*EAPG_Cnst.UTIWAKE_SG*/5 THEN
                        lHokenzeiShu := /*EAPG_Cnst.HOKENSHU_SIEN*/2;
                    WHEN /*EAPG_Cnst.UTIWAKE_KG*/8 THEN
                        lHokenzeiShu := /*EAPG_Cnst.HOKENSHU_KAIGO*/3;
                    WHEN /*EAPG_Cnst.UTIWAKE_KD*/11 THEN
                        lHokenzeiShu := /*EAPG_Cnst.HOKENSHU_KODOMO*/4;
        -- @us 26/xx/xx RG-EA-25-0002
                END CASE;

                FOR j IN /*EAPG_Cnst.IDX_APR1*/0 .. /*IDX_MAX*/12 LOOP
                    EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[i];
                    EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                    EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[j];
                    IF EAPG_SichosonKisoFileT$FukaGendoSisanR.Hihosu > 0 THEN
                        EAPG_SichosonKisoFileT$Write_Flg[i] := 1;
                        -- 均等割額
                        IF makieya.array_length(EAPG_SichosonKisoFileT$SichosonKisoFileParm_) = 0 THEN
                            RAISE using errcode = 'MKER1';
                        END IF;
                        EAPG_SichosonKisoFileT$FukaGendoSisanR.KintoWr := EAPG_SichosonKisoFileT$SichosonKisoFileParm_[lHokenzeiShu].KintoWari * EAPG_SichosonKisoFileT$FukaGendoSisanR.Hihosu;
                        -- 平等割額
                        IF EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn = /*EAPG_Cnst.BYODOH_GAITO*/1 THEN
                            -- 市町村基礎ファイルパラメータマスタより平等割額を取得し計算します
                            EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoWr := makieya.Trunc(EAPG_SichosonKisoFileT$SichosonKisoFileParm_[lHokenzeiShu].ByodoWari::float / 2);

                        ELSIF EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn = /*EAPG_Cnst.BYODOH_GAITO2*/3 THEN
                            -- 市町村基礎ファイルパラメータマスタより平等割額を取得し計算します
                            EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoWr := makieya.Trunc((EAPG_SichosonKisoFileT$SichosonKisoFileParm_[lHokenzeiShu].ByodoWari::float / 4) * 3);
                        ELSE
                            EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoWr := EAPG_SichosonKisoFileT$SichosonKisoFileParm_[lHokenzeiShu].ByodoWari;
                        END IF;

                        IF lFukaDRireki.KeigenKbn != /*EAPG_Cnst.KEIGEN_NASI*/0 THEN
                            -- 均等割軽減額
                            EAPG_SichosonKisoFileT$FukaGendoSisanR.KintoWrKei := EAPG_SichosonKisoFileT$Keigen_[lHokenzeiShu].KintoWrKei * EAPG_SichosonKisoFileT$FukaGendoSisanR.Hihosu;

                            IF EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn = /*EAPG_Cnst.BYODOH_GAITO*/1 THEN
                                EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoWrKei := EAPG_SichosonKisoFileT$Keigen_[lHokenzeiShu].ByodoWrHKei;
                            ELSIF EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn = /*EAPG_Cnst.BYODOH_GAITO2*/3 THEN
                                EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoWrKei := EAPG_SichosonKisoFileT$Keigen_[lHokenzeiShu].ByodoWrHKei
                                                                + CEIL(EAPG_SichosonKisoFileT$Keigen_[lHokenzeiShu].ByodoWrHKei::float / 2);
                            ELSE
                                EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoWrKei := EAPG_SichosonKisoFileT$Keigen_[lHokenzeiShu].ByodoWrKei;
                            END IF;
                        END IF;
                        EAPG_SichosonKisoFileT$FukaGendoSisan_R[j] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                        EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                        EAPG_SichosonKisoFileT$FukaGendoSisan_[i] := EAPG_SichosonKisoFileT$FukaGendoSisanT;
                    END IF;
                END LOOP;

            -- 一般の場合
            ELSIF i IN (/*EAPG_Cnst.UTIWAKE_II*/3, /*EAPG_Cnst.UTIWAKE_SI*/6, /*EAPG_Cnst.UTIWAKE_KI*/9) THEN
                FOR j IN /*EAPG_Cnst.IDX_APR1*/0 .. /*IDX_MAX*/12 LOOP
                    EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[i - 1];
                    EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                    EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[j];
                    EAPG_SichosonKisoFileT$FukaGendoSisan1T := EAPG_SichosonKisoFileT$FukaGendoSisan_[i + 1];
                    EAPG_SichosonKisoFileT$FukaGendoSisan1_R := EAPG_SichosonKisoFileT$FukaGendoSisan1T.TIXSisan;
                    EAPG_SichosonKisoFileT$FukaGendoSisan1R := EAPG_SichosonKisoFileT$FukaGendoSisan1_R[j];
                    IF EAPG_SichosonKisoFileT$FukaGendoSisanR.Hihosu - EAPG_SichosonKisoFileT$FukaGendoSisan1R.Hihosu > 0 THEN
                        EAPG_SichosonKisoFileT$Write_Flg[i] := 1;
                    END IF;
                END LOOP;

            -- 退職の場合
            ELSE
                FOR j IN /*EAPG_Cnst.IDX_APR1*/0 .. /*IDX_MAX*/12 LOOP
                    EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[i];
                    EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                    EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[j];
                    IF EAPG_SichosonKisoFileT$FukaGendoSisanR.Hihosu > 0 THEN
                        EAPG_SichosonKisoFileT$Write_Flg[i] := 1;
                    END IF;
                END LOOP;
            END IF;
        END LOOP;

        PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'Write_Flg', EAPG_SichosonKisoFileT$Write_Flg);
        -- 賦課合計金額、限度超過額、算定額の計算
        -- 均等割額、平等割額、均等割軽減額、平等割軽減額の計算（退職分）
        FOR i IN /*EAPG_Cnst.UTIWAKE_IG*/2 .. /*EAPG_Cnst.UTIWAKE_KD*/11 LOOP
            -- 合計の場合
            IF i IN (/*EAPG_Cnst.UTIWAKE_IG*/2, /*EAPG_Cnst.UTIWAKE_SG*/5, /*EAPG_Cnst.UTIWAKE_KG*/8, /*EAPG_Cnst.UTIWAKE_KD*/11) THEN
                lFlg := 1;
                CASE i
                    WHEN /*EAPG_Cnst.UTIWAKE_IG*/2 THEN
                        lHokenzeiShu := /*EAPG_Cnst.HOKENSHU_IRYO*/1;
                    WHEN /*EAPG_Cnst.UTIWAKE_SG*/5 THEN
                        lHokenzeiShu := /*EAPG_Cnst.HOKENSHU_SIEN*/2;
                    WHEN /*EAPG_Cnst.UTIWAKE_KG*/8 THEN
                        lHokenzeiShu := /*EAPG_Cnst.HOKENSHU_KAIGO*/3;
                    WHEN /*EAPG_Cnst.UTIWAKE_KD*/11 THEN
                        lHokenzeiShu := /*EAPG_Cnst.HOKENSHU_KODOMO*/4;
                END CASE;

                IF lFlg = 1 THEN
                    FOR j IN /*EAPG_Cnst.IDX_APR1*/0 .. /*IDX_MAX*/12 LOOP
                        EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[i];
                        EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                        EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[j];
                        IF EAPG_SichosonKisoFileT$FukaGendoSisanR.Hihosu > 0 THEN
                            -- 賦課合計金額
                            lWorkG := EAPG_SichosonKisoFileT$FukaGendoSisanR.ShtkWr
                                    + EAPG_SichosonKisoFileT$FukaGendoSisanR.SisanWr
                                    + EAPG_SichosonKisoFileT$FukaGendoSisanR.KintoWr
                                    + EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoWr
                                    - EAPG_SichosonKisoFileT$FukaGendoSisanR.KintoWrKei
                                    - EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoWrKei;

                            -- 限度超過額、算定額
                            -- @u 18/10/26 RM-EA-17-0051
                            IF makieya.array_length(EAPG_SichosonKisoFileT$SichosonKisoFileParm_) = 0 THEN
                                RAISE using errcode = 'MKER1';
                            END IF;
                            IF lWorkG > EAPG_SichosonKisoFileT$SichosonKisoFileParm_[lHokenzeiShu].TGendoGak THEN
                                -- @u 18/10/26 RM-EA-17-0051
                                EAPG_SichosonKisoFileT$FukaGendoSisanR.SanteiGak := EAPG_SichosonKisoFileT$SichosonKisoFileParm_[lHokenzeiShu].TGendoGak;
                                EAPG_SichosonKisoFileT$FukaGendoSisan_R[j] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                                EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                                EAPG_SichosonKisoFileT$FukaGendoSisan_[i] := EAPG_SichosonKisoFileT$FukaGendoSisanT;
                            ELSE
                                EAPG_SichosonKisoFileT$FukaGendoSisanR.SanteiGak := lWorkG;
                                EAPG_SichosonKisoFileT$FukaGendoSisan_R[j] = EAPG_SichosonKisoFileT$FukaGendoSisanR;
                                EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                                EAPG_SichosonKisoFileT$FukaGendoSisan_[i] := EAPG_SichosonKisoFileT$FukaGendoSisanT;
                            END IF;
                        END IF;

                        -- 退職を計算する
                        EAPG_SichosonKisoFileT$FukaGendoSisan1T := EAPG_SichosonKisoFileT$FukaGendoSisan_[i + 2];
                        EAPG_SichosonKisoFileT$FukaGendoSisan1_R := EAPG_SichosonKisoFileT$FukaGendoSisan1T.TIXSisan;
                        EAPG_SichosonKisoFileT$FukaGendoSisan1R := EAPG_SichosonKisoFileT$FukaGendoSisan1_R[j];
                        IF EAPG_SichosonKisoFileT$FukaGendoSisan1R.Hihosu > 0 THEN
                            EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[i];
                            EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                            EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[j];
                            -- 退職単独世帯の場合、退職＝ 合計
                            IF EAPG_SichosonKisoFileT$FukaGendoSisan1R.Hihosu = EAPG_SichosonKisoFileT$FukaGendoSisanR.Hihosu THEN
                                EAPG_SichosonKisoFileT$FukaGendoSisan1R.ByodoHKbn  := EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn;
                                EAPG_SichosonKisoFileT$FukaGendoSisan1R.ShtkWr     := EAPG_SichosonKisoFileT$FukaGendoSisanR.ShtkWr;
                                EAPG_SichosonKisoFileT$FukaGendoSisan1R.SisanWr    := EAPG_SichosonKisoFileT$FukaGendoSisanR.SisanWr;
                                EAPG_SichosonKisoFileT$FukaGendoSisan1R.KintoWr    := EAPG_SichosonKisoFileT$FukaGendoSisanR.KintoWr;
                                EAPG_SichosonKisoFileT$FukaGendoSisan1R.ByodoWr    := EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoWr;
                                EAPG_SichosonKisoFileT$FukaGendoSisan1R.KintoWrKei := EAPG_SichosonKisoFileT$FukaGendoSisanR.KintoWrKei;
                                EAPG_SichosonKisoFileT$FukaGendoSisan1R.ByodoWrKei := EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoWrKei;
                                EAPG_SichosonKisoFileT$FukaGendoSisan1R.SanteiGak  := EAPG_SichosonKisoFileT$FukaGendoSisanR.SanteiGak;
                            -- 混合世帯の場合、退職分を計算する
                            ELSE
                                -- 所得割額 … 所得の比で按分 ・小数点以下切り上げ
                                IF EAPG_SichosonKisoFileT$FukaGendoSisanR.ShtkWr > 0 THEN
                                    EAPG_SichosonKisoFileT$FukaGendoSisan1R.ShtkWr
                                     := CEIL((EAPG_SichosonKisoFileT$FukaGendoSisanR.ShtkWr * EAPG_SichosonKisoFileT$FukaGendoSisan1R.ShtkTGak)::float / EAPG_SichosonKisoFileT$FukaGendoSisanR.ShtkTGak);
                                ELSE
                                    EAPG_SichosonKisoFileT$FukaGendoSisan1R.ShtkWr := 0;
                                END IF;
                                -- 資産割額 … 資産の比で按分 ・小数点以下切り上げ

                                IF EAPG_SichosonKisoFileT$FukaGendoSisanR.SisanWr > 0 THEN
                                    EAPG_SichosonKisoFileT$FukaGendoSisan1R.SisanWr
                                     := CEIL((EAPG_SichosonKisoFileT$FukaGendoSisanR.SisanWr * EAPG_SichosonKisoFileT$FukaGendoSisan1R.SisanTGak)::float / EAPG_SichosonKisoFileT$FukaGendoSisanR.SisanTGak);
                                ELSE
                                    EAPG_SichosonKisoFileT$FukaGendoSisan1R.SisanWr := 0;
                                END IF;
                                -- 均等割額 … 被保険者数の比で按分 ・小数点以下切り上げ
                                IF EAPG_SichosonKisoFileT$FukaGendoSisanR.KintoWr > 0 THEN
                                    EAPG_SichosonKisoFileT$FukaGendoSisan1R.KintoWr
                                     := CEIL((EAPG_SichosonKisoFileT$FukaGendoSisanR.KintoWr * EAPG_SichosonKisoFileT$FukaGendoSisan1R.Hihosu)::float / EAPG_SichosonKisoFileT$FukaGendoSisanR.Hihosu);
                                ELSE
                                    EAPG_SichosonKisoFileT$FukaGendoSisan1R.KintoWr := 0;
                                END IF;
                                -- 均等割軽減額 … 被保険者数の比で按分 ・小数点以下切り上げ
                                IF EAPG_SichosonKisoFileT$FukaGendoSisanR.KintoWrKei > 0 THEN
                                    EAPG_SichosonKisoFileT$FukaGendoSisan1R.KintoWrKei
                                     := CEIL((EAPG_SichosonKisoFileT$FukaGendoSisanR.KintoWrKei * EAPG_SichosonKisoFileT$FukaGendoSisan1R.Hihosu)::float / EAPG_SichosonKisoFileT$FukaGendoSisanR.Hihosu);
                                ELSE
                                    EAPG_SichosonKisoFileT$FukaGendoSisan1R.KintoWrKei := 0;
                                END IF;
                                -- 平等割額、平等割軽減額
                                -- 混合世帯の場合、平等割額は一般分になる
                                EAPG_SichosonKisoFileT$FukaGendoSisan1R.ByodoWr    := 0;
                                EAPG_SichosonKisoFileT$FukaGendoSisan1R.ByodoWrKei := 0;

                                -- 退職分賦課合計金額
                                lWorkT := EAPG_SichosonKisoFileT$FukaGendoSisan1R.ShtkWr
                                        + EAPG_SichosonKisoFileT$FukaGendoSisan1R.SisanWr
                                        + EAPG_SichosonKisoFileT$FukaGendoSisan1R.KintoWr
                                        - EAPG_SichosonKisoFileT$FukaGendoSisan1R.KintoWrKei;

                                -- 限度超過額、算定額
                                -- 限度額該当世帯の場合
                                -- @u 18/10/26 RM-EA-17-0051
                                IF makieya.array_length(EAPG_SichosonKisoFileT$SichosonKisoFileParm_) = 0 THEN
                                    RAISE using errcode = 'MKER1';
                                END IF;
                                IF lWorkG > EAPG_SichosonKisoFileT$SichosonKisoFileParm_[lHokenzeiShu].TGendoGak THEN
                                    -- 算定額：賦課合計金額の比で按分 ・小数点以下切り上げ
                                    -- @u 18/10/26 RM-EA-17-0051
                                    lWork := CEIL((EAPG_SichosonKisoFileT$SichosonKisoFileParm_[lHokenzeiShu].TGendoGak * lWorkT)::float / lWorkG);
                                    CALL EAPG_SichosonKisoFileT$CheckKingaku(lWork);
                                    EAPG_SichosonKisoFileT$FukaGendoSisan1R.SanteiGak := lWork;
                                ELSE
                                    EAPG_SichosonKisoFileT$FukaGendoSisan1R.SanteiGak := lWorkT;
                                END IF;

                            END IF;
                            EAPG_SichosonKisoFileT$FukaGendoSisan1_R[j] := EAPG_SichosonKisoFileT$FukaGendoSisan1R;
                            EAPG_SichosonKisoFileT$FukaGendoSisan1T.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan1_R;
                            EAPG_SichosonKisoFileT$FukaGendoSisan_[i + 2] := EAPG_SichosonKisoFileT$FukaGendoSisan1T;
                        END IF;
                    END LOOP;
                END IF;
            END IF;
        END LOOP;
        PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan_', EAPG_SichosonKisoFileT$FukaGendoSisan_);

        EAPG_SichosonKisoFileT$Write_Flg = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'Write_Flg', EAPG_SichosonKisoFileT$Write_Flg);
        EAPG_SichosonKisoFileT$FukaGendoSisan2_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan2_', EAPG_SichosonKisoFileT$FukaGendoSisan2_);

        -- 賦課年間額を計算する
        -- 賦課限度額控除後試算ワーク
        -- @u 26/xx/xx RG-EA-25-0002 子ども・子育て支援金制度の創設対応（３次）
        FOR i IN /*EAPG_Cnst.UTIWAKE_IG*/2 .. /*EAPG_Cnst.UTIWAKE_KD*/11 LOOP
            -- 合計と退職の場合
            IF i IN (/*EAPG_Cnst.UTIWAKE_IG*/2
                    ,/*EAPG_Cnst.UTIWAKE_IT*/4
                    ,/*EAPG_Cnst.UTIWAKE_SG*/5
                    ,/*EAPG_Cnst.UTIWAKE_ST*/7
                    ,/*EAPG_Cnst.UTIWAKE_KG*/8
                    ,/*EAPG_Cnst.UTIWAKE_KT*/10
                    -- @a 26/xx/xx RG-EA-25-0002 子ども・子育て支援金制度の創設対応（３次）
                    ,/*EAPG_Cnst.UTIWAKE_KD*/11) AND
               EAPG_SichosonKisoFileT$Write_Flg[i] = 1 THEN
                -- 月別額を合計
                FOR j IN /*EAPG_Cnst.IDX_APR*/1 .. /*EAPG_Cnst.IDX_MAR*/12 LOOP
                    EAPG_SichosonKisoFileT$FukaGendoSisanT := EAPG_SichosonKisoFileT$FukaGendoSisan_[i];
                    EAPG_SichosonKisoFileT$FukaGendoSisan_R := EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan;
                    EAPG_SichosonKisoFileT$FukaGendoSisanR := EAPG_SichosonKisoFileT$FukaGendoSisan_R[j];
                    item = EAPG_SichosonKisoFileT$FukaGendoSisan2_[i];
                    IF EAPG_SichosonKisoFileT$FukaGendoSisan2_[i].ShtkTGak = 0
                    AND EAPG_SichosonKisoFileT$FukaGendoSisanR.ShtkTGak > 0 THEN
                        item.ShtkTGak   := EAPG_SichosonKisoFileT$FukaGendoSisanR.ShtkTGak;
                    END IF;

                    IF EAPG_SichosonKisoFileT$FukaGendoSisan2_[i].SisanTGak = 0
                    AND EAPG_SichosonKisoFileT$FukaGendoSisanR.SisanTGak > 0 THEN
                        item.SisanTGak  := EAPG_SichosonKisoFileT$FukaGendoSisanR.SisanTGak;
                    END IF;
                    item.ShtkWr     := EAPG_SichosonKisoFileT$FukaGendoSisan2_[i].ShtkWr     + EAPG_SichosonKisoFileT$FukaGendoSisanR.ShtkWr;
                    item.SisanWr    := EAPG_SichosonKisoFileT$FukaGendoSisan2_[i].SisanWr    + EAPG_SichosonKisoFileT$FukaGendoSisanR.SisanWr;
                    item.KintoWr    := EAPG_SichosonKisoFileT$FukaGendoSisan2_[i].KintoWr    + EAPG_SichosonKisoFileT$FukaGendoSisanR.KintoWr;
                    item.ByodoWr    := EAPG_SichosonKisoFileT$FukaGendoSisan2_[i].ByodoWr    + EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoWr;
                    item.KintoWrKei := EAPG_SichosonKisoFileT$FukaGendoSisan2_[i].KintoWrKei + EAPG_SichosonKisoFileT$FukaGendoSisanR.KintoWrKei;
                    item.ByodoWrKei := EAPG_SichosonKisoFileT$FukaGendoSisan2_[i].ByodoWrKei + EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoWrKei;
                    item.SanteiGak  := EAPG_SichosonKisoFileT$FukaGendoSisan2_[i].SanteiGak  + EAPG_SichosonKisoFileT$FukaGendoSisanR.SanteiGak;
                    item.Hihosu     := EAPG_SichosonKisoFileT$FukaGendoSisanR.Hihosu;
                    item.ByodoHKbn  := EAPG_SichosonKisoFileT$FukaGendoSisanR.ByodoHKbn;
                    EAPG_SichosonKisoFileT$FukaGendoSisan2_[i] = item;
                END LOOP;

                -- 合計を12で割る
                -- 所得割額等は、1円未満四捨五入
                item = EAPG_SichosonKisoFileT$FukaGendoSisan2_[i];
                item.ShtkWr     := oracle.round(EAPG_SichosonKisoFileT$FukaGendoSisan2_[i].ShtkWr::float     / 12, 0);
                item.SisanWr    := oracle.round(EAPG_SichosonKisoFileT$FukaGendoSisan2_[i].SisanWr::float    / 12, 0);
                item.KintoWr    := oracle.round(EAPG_SichosonKisoFileT$FukaGendoSisan2_[i].KintoWr::float    / 12, 0);
                item.ByodoWr    := oracle.round(EAPG_SichosonKisoFileT$FukaGendoSisan2_[i].ByodoWr::float    / 12, 0);
                item.KintoWrKei := oracle.round(EAPG_SichosonKisoFileT$FukaGendoSisan2_[i].KintoWrKei::float / 12, 0);
                item.ByodoWrKei := oracle.round(EAPG_SichosonKisoFileT$FukaGendoSisan2_[i].ByodoWrKei::float / 12, 0);
                item.SanteiGak  := FLOOR(EAPG_SichosonKisoFileT$FukaGendoSisan2_[i].SanteiGak::float  / 12);
                EAPG_SichosonKisoFileT$FukaGendoSisan2_[i] = item;
            END IF;
        END LOOP;

        -- 一般分を計算（一般＝合計－退職分）
        FOR i IN /*EAPG_Cnst.UTIWAKE_IG*/2 .. /*EAPG_Cnst.UTIWAKE_KD*/11 LOOP
            -- 一般の場合
            IF i IN (/*EAPG_Cnst.UTIWAKE_II*/3
                    ,/*EAPG_Cnst.UTIWAKE_SI*/6
                    ,/*EAPG_Cnst.UTIWAKE_KI*/9
                    ,/*EAPG_Cnst.UTIWAKE_KD*/11) AND
               EAPG_SichosonKisoFileT$Write_Flg[i] = 1 THEN
                item = EAPG_SichosonKisoFileT$FukaGendoSisan2_[i];
                item.ShtkTGak   := EAPG_SichosonKisoFileT$FukaGendoSisan2_[i - 1].ShtkTGak   - EAPG_SichosonKisoFileT$FukaGendoSisan2_[i + 1].ShtkTGak    ;
                item.SisanTGak  := EAPG_SichosonKisoFileT$FukaGendoSisan2_[i - 1].SisanTGak  - EAPG_SichosonKisoFileT$FukaGendoSisan2_[i + 1].SisanTGak   ;
                item.ShtkWr     := EAPG_SichosonKisoFileT$FukaGendoSisan2_[i - 1].ShtkWr     - EAPG_SichosonKisoFileT$FukaGendoSisan2_[i + 1].ShtkWr    ;
                item.SisanWr    := EAPG_SichosonKisoFileT$FukaGendoSisan2_[i - 1].SisanWr    - EAPG_SichosonKisoFileT$FukaGendoSisan2_[i + 1].SisanWr   ;
                item.KintoWr    := EAPG_SichosonKisoFileT$FukaGendoSisan2_[i - 1].KintoWr    - EAPG_SichosonKisoFileT$FukaGendoSisan2_[i + 1].KintoWr   ;
                item.ByodoWr    := EAPG_SichosonKisoFileT$FukaGendoSisan2_[i - 1].ByodoWr    - EAPG_SichosonKisoFileT$FukaGendoSisan2_[i + 1].ByodoWr   ;
                item.KintoWrKei := EAPG_SichosonKisoFileT$FukaGendoSisan2_[i - 1].KintoWrKei - EAPG_SichosonKisoFileT$FukaGendoSisan2_[i + 1].KintoWrKei;
                item.ByodoWrKei := EAPG_SichosonKisoFileT$FukaGendoSisan2_[i - 1].ByodoWrKei - EAPG_SichosonKisoFileT$FukaGendoSisan2_[i + 1].ByodoWrKei;
                item.SanteiGak  := EAPG_SichosonKisoFileT$FukaGendoSisan2_[i - 1].SanteiGak  - EAPG_SichosonKisoFileT$FukaGendoSisan2_[i + 1].SanteiGak ;
                item.Hihosu     := EAPG_SichosonKisoFileT$FukaGendoSisan2_[i - 1].Hihosu     - EAPG_SichosonKisoFileT$FukaGendoSisan2_[i + 1].Hihosu;
                item.ByodoHKbn  := EAPG_SichosonKisoFileT$FukaGendoSisan2_[i - 1].ByodoHKbn;
                EAPG_SichosonKisoFileT$FukaGendoSisan2_[i] = item;
            END IF;
        END LOOP;
        PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan2_', EAPG_SichosonKisoFileT$FukaGendoSisan2_);

        pRet = /*RETURN_TRUE*/0;
        RETURN;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS SQLCODE = RETURNED_SQLSTATE;
            lErrMsg := concat(/*THIS_PACKAGE*/'EAPG_SichosonKisoFileT' , '.FukaSisan:' , SQLCODE , ' ' , SQLERRM , ' ');
            CALL CBPG_ERRLOG$PRC_Logging(lErrMsg);
            pRet = /*RETURN_FALSE*/1;
            RETURN;

    END;

$$ LANGUAGE plpgsql;

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    -- 賦課限度額控除後試算ワークをを更新します。
    -- %usage
    -- 賦課限度額控除後試算ワークをを更新します。
    -- %param pFukaGendoSisan 賦課限度額控除後試算ワーク作成情報
    -- %return 戻り値
    --     {*}  0 正常終了
    --     {*}  1 異常終了
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    CREATE OR REPLACE FUNCTION EAPG_SichosonKisoFileT$NewSisanWork(pFukaGendoSisan IN EATW_FUKAGENDOSISAN)
    RETURNS numeric


AS $$

    DECLARE
        SQLCODE varchar;
        lErrMsg varchar(1000);
    BEGIN
        INSERT INTO EATW_FukaGendoSisan
            (Fukanendo,
             Kokuhono,
             Setainusino,
             Utiwakekbn,
             Shtktgak,
             Sisantgak,
             Hihosu,
             Byodohkbn,
             Shtkwr,
             Sisanwr,
             Kintowr,
             Byodowr,
             Kintowrkei,
             Byodowrkei,
             Santeigak,
             Regdate,
             Regstaffid)
        VALUES
            (pFukaGendoSisan.Fukanendo,
             pFukaGendoSisan.Kokuhono,
             pFukaGendoSisan.Setainusino,
             pFukaGendoSisan.Utiwakekbn,
             pFukaGendoSisan.Shtktgak,
             pFukaGendoSisan.Sisantgak,
             pFukaGendoSisan.Hihosu,
             pFukaGendoSisan.Byodohkbn,
             pFukaGendoSisan.Shtkwr,
             pFukaGendoSisan.Sisanwr,
             pFukaGendoSisan.Kintowr,
             pFukaGendoSisan.Byodowr,
             pFukaGendoSisan.Kintowrkei,
             pFukaGendoSisan.Byodowrkei,
             pFukaGendoSisan.Santeigak,
             makieya.SysDateTime(),
             CAPG_Context$StaffID());

        RETURN /*RETURN_TRUE*/0;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS SQLCODE = RETURNED_SQLSTATE;
            lErrMsg := concat(/*THIS_PACKAGE*/'EAPG_SichosonKisoFileT' , '.NewSisanWork:' , SQLCODE , ' ' , SQLERRM , ' ');
            CALL CBPG_ERRLOG$PRC_Logging(lErrMsg);
            RETURN /*RETURN_FALSE*/1;

    END;

$$ LANGUAGE plpgsql;

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    -- 市町村基礎ファイル（退職保険料・保険料軽減額）ワークを更新します。
    -- %usage
    -- 市町村基礎ファイル（退職保険料・保険料軽減額）ワークを更新します。
    -- %param pFukaNendo        賦課年度
    -- %param pKankatuCd        管轄コード
    -- %return 戻り値
    --     {*}  0 正常終了
    --     {*}  1 異常終了
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    CREATE OR REPLACE FUNCTION EAPG_SichosonKisoFileT$NewSichosonFileTWork(pFukaNendo       IN numeric,
                              pKankatuCd       IN numeric)
    RETURNS numeric


AS $$

    DECLARE
        EAPG_SichosonKisoFileT$SichosonKisoFileParm_ EATM_SichosonKisoFileParm[];
        EAPG_SichosonKisoFileT$SichosonKisoFileT_ EATW_SichosonKisoFileT%ROWTYPE;
        SQLCODE varchar;
        lKankatuCd     numeric(2, 0);
        lMaxLen        numeric(1, 0)     := 8;
        lKokuhoNo      EATW_SichosonKisoFileT.KokuhoNo%TYPE;
        lSetainusiNo   EATW_SichosonKisoFileT.SetainusiNo%TYPE;
        lHokenshaNo    EATW_SichosonKisoFileT.HokenshaNo%TYPE;
        lShtktgak      EATW_SichosonKisoFileT.Shtktgak%TYPE;
        lSisantgak     EATW_SichosonKisoFileT.Sisantgak%TYPE;
        lKeigengkIryo  EATW_SichosonKisoFileT.Keigengkiryo%TYPE;
        lKeigengkSien  EATW_SichosonKisoFileT.Keigengksien%TYPE;
        lKeigengkKaigo EATW_SichosonKisoFileT.Keigengkkaigo%TYPE;
        -- @a 25/08/29 RM-EA-25-0010
        lKeigengkKodomo EATW_SichosonKisoFileT.Keigengkkodomo%TYPE;
        lNofukinIryo   EATW_SichosonKisoFileT.Nofukiniryo%TYPE;
        lNofukinSien   EATW_SichosonKisoFileT.Nofukinsien%TYPE;
        lErrMsg        varchar(1000);

        lCnt           integer;

    BEGIN

        CALL CBPG_PkgVariable$Init();

        -- 一時テーブルの初期化

        PERFORM CBPG_PkgVariable$InitValue('EAPG_SichosonKisoFileT', 'SichosonKisoFileParm_', EAPG_SichosonKisoFileT$SichosonKisoFileParm_);

        PERFORM CBPG_PkgVariable$InitValue('EAPG_SichosonKisoFileT', 'SichosonKisoFileT_', EAPG_SichosonKisoFileT$SichosonKisoFileT_);

        -- 処理開始ジャーナル
        PERFORM CCPG_BATCHJOURNALWRITER$PRC_WriteProcBlockStart(concat('　' , /*THIS_PROC_BLOCK*/'市町村基礎ファイル（退職保険料・保険料軽減額）ワーク作成'));

        -- 管轄コードが未選択の場合、0(全市)を設定する
        IF pKankatuCd = -1 THEN
            lKankatuCd := 0;
        ELSE
            lKankatuCd := pKankatuCd;
        END IF;

        -- 保険者番号を取得
        BEGIN
            SELECT oracle.LPAD(T1.HokenshaNo, lMaxLen::integer, '0')
              INTO STRICT lHokenshaNo
              FROM EATM_HOKENSHANO T1
             WHERE T1.HokenshaKcd = lKankatuCd;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lErrMsg := '保険者番号を取得できなかったため、市町村基礎ファイル（退職保険料・保険料軽減額）ワークを更新できませんでした。';
                PERFORM CCPG_BATCHJOURNALWRITER$PRC_WriteFreeError(lErrMsg);
                RETURN /*RETURN_FALSE*/1;
        END;

        DECLARE
            -- 国保番号、世帯主番号、内訳区分ごとの所得割対象額、資産割対象額、
            -- (均等割軽減額+平等割軽減額）、算定額を取得するカーソル
            csrFukaGendoSisan CURSOR FOR
                SELECT T1.FukaNendo
                     , T1.KokuhoNo
                     , T1.SetainusiNo
                     , T1.UtiwakeKbn
                     , T1.ShtkTGak
                     , T1.SisanTGak
                     , T1.KintowrKei + T1.ByodowrKei AS KeigenGak
                     -- @as 17/11/17 RM-EA-17-0045
                     , T1.KintoWr
                     , T1.KintoWrKei
                     , T1.ByodoWrKei
                     , T1.ByodoHKbn
                     -- @ae 17/11/17 RM-EA-17-0045
                     , T1.SanteiGak
                  FROM EATW_FukaGendoSisan  T1
                 WHERE T1.FukaNendo = pFukaNendo
                 ORDER BY T1.KokuhoNo
                        , T1.SetainusiNo;
        BEGIN
            -- ローカル変数初期化
            lKokuhoNo      := 0;
            lSetainusiNo   := 0;
            lShtktgak      := 0;
            lSisantgak     := 0;
            lKeigengkIryo  := 0;
            lKeigengkSien  := 0;
            lKeigengkKaigo := 0;
            -- @a 25/08/29 RM-EA-25-0010
            lKeigengkKodomo := 0;
            lNofukinIryo   := 0;
            lNofukinSien   := 0;

            lCnt           := 0;
            -- 市町村基礎ファイル（退職保険料・保険料軽減額）作成ワーク初期化
            EAPG_SichosonKisoFileT$SichosonKisoFileT_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'SichosonKisoFileT_', EAPG_SichosonKisoFileT$SichosonKisoFileT_);

            EAPG_SichosonKisoFileT$SichosonKisoFileT_.KokuhoNo                   := 0;
            EAPG_SichosonKisoFileT$SichosonKisoFileT_.SetainusiNo                := 0;
            EAPG_SichosonKisoFileT$SichosonKisoFileT_.Shtktgak                   := 0;
            EAPG_SichosonKisoFileT$SichosonKisoFileT_.Sisantgak                  := 0;
            EAPG_SichosonKisoFileT$SichosonKisoFileT_.HokenshaNo                 := lHokenshaNo;
            EAPG_SichosonKisoFileT$SichosonKisoFileT_.SanteiNendo                := pFukaNendo;
            EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkIryo               := 0;
            EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkSien               := 0;
            EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkKaigo              := 0;
            -- @a 25/08/29 RM-EA-25-0010
            EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkKodomo             := 0;
            EAPG_SichosonKisoFileT$SichosonKisoFileT_.NofukinIryo                := 0;
            EAPG_SichosonKisoFileT$SichosonKisoFileT_.NofukinSien                := 0;

            EAPG_SichosonKisoFileT$SichosonKisoFileParm_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'SichosonKisoFileParm_', EAPG_SichosonKisoFileT$SichosonKisoFileParm_);
            FOR recFukaGendoSisan IN csrFukaGendoSisan LOOP
                IF recFukaGendoSisan.KokuhoNo <> lKokuhoNo
                OR recFukaGendoSisan.SetainusiNo <> lSetainusiNo THEN
                    IF lKokuhoNo <> 0 THEN

                        EAPG_SichosonKisoFileT$SichosonKisoFileT_.Shtktgak            := lShtktgak;
                        EAPG_SichosonKisoFileT$SichosonKisoFileT_.Sisantgak           := lSisantgak;
                        EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkIryo        := lKeigengkiryo;
                        EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkSien        := lKeigengksien;
                        EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkKaigo       := lKeigengkkaigo;
                        -- @a 25/08/29 RM-EA-25-0010
                        EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkKodomo      := lKeigengkKodomo;
                        EAPG_SichosonKisoFileT$SichosonKisoFileT_.NofukinIryo         := lNofukiniryo;
                        EAPG_SichosonKisoFileT$SichosonKisoFileT_.NofukinSien         := lNofukinsien;

                        INSERT INTO EATW_SichosonKisoFileT
                            (Kokuhono,
                             Setainusino,
                             Shtktgak,
                             Sisantgak,
                             Hokenshano,
                             Santeinendo,
                             Keigengkiryo,
                             Keigengksien,
                             Keigengkkaigo,
                             -- @a 25/08/29 RM-EA-25-0010
                             Keigengkkodomo,
                             Nofukiniryo,
                             Nofukinsien,
                             Regdate,
                             Regstaffid)
                        VALUES
                            (EAPG_SichosonKisoFileT$SichosonKisoFileT_.KokuhoNo,
                             EAPG_SichosonKisoFileT$SichosonKisoFileT_.SetainusiNo,
                             EAPG_SichosonKisoFileT$SichosonKisoFileT_.Shtktgak,
                             EAPG_SichosonKisoFileT$SichosonKisoFileT_.Sisantgak,
                             EAPG_SichosonKisoFileT$SichosonKisoFileT_.HokenshaNo,
                             EAPG_SichosonKisoFileT$SichosonKisoFileT_.SanteiNendo,
                             EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkIryo,
                             EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkSien,
                             EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkKaigo,
                             -- @a 25/08/29 RM-EA-25-0010
                             EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkKodomo,
                             EAPG_SichosonKisoFileT$SichosonKisoFileT_.NofukinIryo,
                             EAPG_SichosonKisoFileT$SichosonKisoFileT_.NofukinSien,
                             makieya.SysDateTime(),
                             CAPG_Context$StaffID());

                        -- 処理経過ジャーナル
                        lCnt := lCnt + 1;
                        PERFORM CCPG_BATCHJOURNALWRITER$PRC_WriteProcBlockProsessing(concat('　　' , /*THIS_PROC_BLOCK*/'市町村基礎ファイル（退職保険料・保険料軽減額）ワーク作成'), lCnt);
                    END IF;
                    -- ローカル変数初期化
                    lKokuhoNo      := recFukaGendoSisan.KokuhoNo;
                    lSetainusiNo   := recFukaGendoSisan.SetainusiNo;
                    lShtktgak      := 0;
                    lSisantgak     := 0;
                    lKeigengkIryo  := 0;
                    lKeigengkSien  := 0;
                    lKeigengkKaigo := 0;
                    -- @a 25/08/29 RM-EA-25-0010
                    lKeigengkKodomo := 0;
                    lNofukinIryo   := 0;
                    lNofukinSien   := 0;
                    -- 市町村基礎ファイル（退職保険料・保険料軽減額）作成ワーク初期化

                    EAPG_SichosonKisoFileT$SichosonKisoFileT_.KokuhoNo                   := lKokuhoNo;
                    EAPG_SichosonKisoFileT$SichosonKisoFileT_.SetainusiNo                := lSetainusiNo;
                    EAPG_SichosonKisoFileT$SichosonKisoFileT_.Shtktgak                   := 0;
                    EAPG_SichosonKisoFileT$SichosonKisoFileT_.Sisantgak                  := 0;
                    EAPG_SichosonKisoFileT$SichosonKisoFileT_.HokenshaNo                 := lHokenshaNo;
                    EAPG_SichosonKisoFileT$SichosonKisoFileT_.SanteiNendo                := pFukaNendo;
                    EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkIryo               := 0;
                    EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkSien               := 0;
                    EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkKaigo              := 0;
                    -- @a 25/08/29 RM-EA-25-0010
                    EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkKodomo             := 0;
                    EAPG_SichosonKisoFileT$SichosonKisoFileT_.NofukinIryo                := 0;
                    EAPG_SichosonKisoFileT$SichosonKisoFileT_.NofukinSien                := 0;

                END IF;
                IF recFukaGendoSisan.Shtktgak > 0
                AND lShtktgak = 0 THEN
                    lShtktgak      := recFukaGendoSisan.Shtktgak;                         --所得割対象額
                END IF;

                IF  recFukaGendoSisan.Sisantgak > 0
                AND lSisantgak = 0 THEN
                    lSisantgak     := recFukaGendoSisan.Sisantgak;                        --資産割対象額
                END IF;

                CASE recFukaGendoSisan.UtiwakeKbn
                    -- 3:医療分（一般）
                    WHEN /*EAPG_Cnst.UTIWAKE_II*/3 THEN
                        -- @us 17/11/17 RM-EA-17-0045
                        --医療分軽減額
                        lKeigengkIryo  := lKeigengkIryo  + recFukaGendoSisan.KintoWrKei;   --均等割軽減額

                        -- 平等割軽減額を算出する
                        IF recFukaGendoSisan.ByodowrKei > 0 THEN
                            CASE recFukaGendoSisan.ByodoHKbn
                                WHEN /*EAPG_Cnst.BYODOH_HIGAITO*/2 THEN
                                    lKeigengkIryo := lKeigengkIryo + recFukaGendoSisan.ByodoWrKei;
                                ELSE
                                    -- 平等割額軽減区分が「非該当」でない場合、平等割軽減額には1/2軽減または1/4軽減にて算出された値が入っているため、
                                    -- 均等割額軽減/均等割額の割合を元に、平等割額軽減を再計算して設定する。
                                    IF makieya.array_length(EAPG_SichosonKisoFileT$SichosonKisoFileParm_) = 0 THEN
                                        RAISE using errcode = 'MKER1';
                                    END IF;
                                    lKeigengkIryo := lKeigengkIryo + CEIL(EAPG_SichosonKisoFileT$SichosonKisoFileParm_[/*EAPG_Cnst.HOKENSHU_IRYO*/1].ByodoWari * oracle.round(recFukaGendoSisan.KintoWrKei::float / recFukaGendoSisan.KintoWr, 1));
                            END CASE;
                        END IF;
                        -- @ue 17/11/17 RM-EA-17-0045

                    -- 4:医療分（退職）
                    WHEN /*EAPG_Cnst.UTIWAKE_IT*/4 THEN
                        lNofukinIryo   := lNofukinIryo   + recFukaGendoSisan.SanteiGak;   --退職者医療分算定額

                    -- 6:支援金分（一般）
                    WHEN /*EAPG_Cnst.UTIWAKE_SI*/6 THEN
                        -- @us 17/11/17 RM-EA-17-0045
                        --支援金分軽減額
                        lKeigengkSien  := lKeigengkSien  + recFukaGendoSisan.KintoWrKei;   --均等割軽減額

                        -- 平等割軽減額を算出する
                        IF recFukaGendoSisan.ByodowrKei > 0 THEN
                            CASE recFukaGendoSisan.ByodoHKbn
                                WHEN /*EAPG_Cnst.BYODOH_HIGAITO*/2 THEN
                                    lKeigengkSien := lKeigengkSien + recFukaGendoSisan.ByodoWrKei;
                                ELSE
                                    IF makieya.array_length(EAPG_SichosonKisoFileT$SichosonKisoFileParm_) = 0 THEN
                                        RAISE using errcode = 'MKER1';
                                    END IF;
                                    lKeigengkSien := lKeigengkSien + CEIL(EAPG_SichosonKisoFileT$SichosonKisoFileParm_[/*EAPG_Cnst.HOKENSHU_SIEN*/2].ByodoWari * oracle.round(recFukaGendoSisan.KintoWrKei::float / recFukaGendoSisan.KintoWr, 1));
                            END CASE;
                        END IF;
                        -- @ue 17/11/17 RM-EA-17-0045

                    -- 7:支援金分（退職）
                    WHEN /*EAPG_Cnst.UTIWAKE_ST*/7 THEN
                        lNofukinSien   := lNofukinSien   + recFukaGendoSisan.SanteiGak;   --退職者支援金分算定額

                    -- 9:介護分（一般）
                    WHEN /*EAPG_Cnst.UTIWAKE_KI*/9 THEN
                        lKeigengkKaigo := lKeigengkKaigo + recFukaGendoSisan.KeigenGak;   --介護分軽減額

                    -- @as 26/xx/xx RG-EA-25-0002 子ども・子育て支援金制度の創設対応（３次）
                    -- 11:子ども分
                    WHEN /*EAPG_Cnst.UTIWAKE_KD*/11 THEN
                        lKeigengkKodomo := lKeigengkKodomo + recFukaGendoSisan.KintoWrKei;   --子ども分軽減額

                        -- 平等割軽減額を算出する
                        IF recFukaGendoSisan.ByodowrKei > 0 THEN
                            CASE recFukaGendoSisan.ByodoHKbn
                                WHEN /*EAPG_Cnst.BYODOH_HIGAITO*/2 THEN
                                    lKeigengkKodomo := lKeigengkKodomo + recFukaGendoSisan.ByodoWrKei;
                                ELSE
                                    IF makieya.array_length(EAPG_SichosonKisoFileT$SichosonKisoFileParm_) = 0 THEN
                                        RAISE using errcode = 'MKER1';
                                    END IF;
                                    lKeigengkKodomo := lKeigengkKodomo + CEIL(EAPG_SichosonKisoFileT$SichosonKisoFileParm_[/*EAPG_Cnst.HOKENSHU_KODOMO*/4].ByodoWari * oracle.round(recFukaGendoSisan.KintoWrKei::float / recFukaGendoSisan.KintoWr, 1));
                            END CASE;
                        END IF;
                    -- @as 26/xx/xx RG-EA-25-0002
                    ELSE
                        NULL;
                END CASE;
            END LOOP;

            PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'SichosonKisoFileT_', EAPG_SichosonKisoFileT$SichosonKisoFileT_);

            -- csrFukaGendoSisanにデータが存在する場合、最終の国保番号、世帯主番号データの情報をINSERTする
            IF lKokuhoNo <> 0 THEN
                EAPG_SichosonKisoFileT$SichosonKisoFileT_.Shtktgak            := lShtktgak;
                EAPG_SichosonKisoFileT$SichosonKisoFileT_.Sisantgak           := lSisantgak;
                EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkIryo        := lKeigengkiryo;
                EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkSien        := lKeigengksien;
                EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkKaigo       := lKeigengkkaigo;
                -- @a 25/08/29 RM-EA-25-0010
                EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkKodomo      := lKeigengkKodomo;
                EAPG_SichosonKisoFileT$SichosonKisoFileT_.NofukinIryo         := lNofukiniryo;
                EAPG_SichosonKisoFileT$SichosonKisoFileT_.NofukinSien         := lNofukinsien;

                INSERT INTO EATW_SichosonKisoFileT
                    (Kokuhono,
                     Setainusino,
                     Shtktgak,
                     Sisantgak,
                     Hokenshano,
                     Santeinendo,
                     Keigengkiryo,
                     Keigengksien,
                     Keigengkkaigo,
                     -- @a 25/08/29 RM-EA-25-0010
                     KeigengkKodomo,
                     Nofukiniryo,
                     Nofukinsien,
                     Regdate,
                     Regstaffid)
                VALUES
                    (EAPG_SichosonKisoFileT$SichosonKisoFileT_.KokuhoNo,
                     EAPG_SichosonKisoFileT$SichosonKisoFileT_.SetainusiNo,
                     EAPG_SichosonKisoFileT$SichosonKisoFileT_.Shtktgak,
                     EAPG_SichosonKisoFileT$SichosonKisoFileT_.Sisantgak,
                     EAPG_SichosonKisoFileT$SichosonKisoFileT_.HokenshaNo,
                     EAPG_SichosonKisoFileT$SichosonKisoFileT_.SanteiNendo,
                     EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkIryo,
                     EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkSien,
                     EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkKaigo,
                     -- @a 25/08/29 RM-EA-25-0010
                     EAPG_SichosonKisoFileT$SichosonKisoFileT_.KeigengkKodomo,
                     EAPG_SichosonKisoFileT$SichosonKisoFileT_.NofukinIryo,
                     EAPG_SichosonKisoFileT$SichosonKisoFileT_.NofukinSien,
                     makieya.SysDateTime(),
                     CAPG_Context$StaffID());

                -- 処理経過ジャーナル
                lCnt := lCnt + 1;
                PERFORM CCPG_BATCHJOURNALWRITER$PRC_WriteProcBlockProsessing(concat('　　' , /*THIS_PROC_BLOCK*/'市町村基礎ファイル（退職保険料・保険料軽減額）ワーク作成'), lCnt);
            END IF;
        END;
        RETURN /*RETURN_TRUE*/0;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS SQLCODE = RETURNED_SQLSTATE;
            lErrMsg := concat(/*THIS_PACKAGE*/'EAPG_SichosonKisoFileT' , '.NewSichosonFileTWork:' , SQLCODE , ' ' , SQLERRM , ' ');
            CALL CBPG_ERRLOG$PRC_Logging(lErrMsg);
            RETURN /*RETURN_FALSE*/1;

    END;

$$ LANGUAGE plpgsql;

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    -- 賦課限度額控除後試算ワーク、市町村基礎ファイル（退職保険料・保険料軽減額）作成ワークを更新します。
    -- %usage
    -- 賦課限度額控除後試算ワーク、市町村基礎ファイル（退職保険料・保険料軽減額）作成ワークを更新します。
    -- %param pFukaNendo          賦課年度
    -- %param pKankatuCd          管轄コード
    -- %return 戻り値
    --     {*}  0 正常終了
    --     {*}  1 異常終了
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
    CREATE OR REPLACE FUNCTION EAPG_SichosonKisoFileT$FNC_SichosonKisoFileT(pFukaNendo         IN numeric,
                                   pKankatuCd         IN numeric)
    RETURNS numeric


AS $$

    DECLARE
        item EATW_FukaGendoSisan;
        EAPG_SichosonKisoFileT$FukaGendoSisan2_ EATW_FukaGendoSisan[];
        lrec record;
        EAPG_SichosonKisoFileT$FukaGendoSisan_ EAPG_SichosonKisoFileT$TY_Sisan_T[];
        EAPG_SichosonKisoFileT$FukaGendoSisanT EAPG_SichosonKisoFileT$TY_Sisan_T;
        EAPG_SichosonKisoFileT$FukaGendoSisan_R EAPG_SichosonKisoFileT$TY_Sisan_R[];
        EAPG_SichosonKisoFileT$Write_Flg numeric[];
        SQLCODE varchar;
        lFukaNendo      numeric;
        lRet1           numeric;
        lRet2           numeric;
        lKeigenKbn      numeric;
        lSetaiCnt       numeric;
        lNmlCnt         numeric;
        lCnt            numeric;
        lErrMsg         varchar(5000);
        lParam          varchar(1000);
        lSikakuKijunYmd timestamp(0) without time zone;
    BEGIN

        CALL CBPG_PkgVariable$Init();

        -- 一時テーブルの初期化

        PERFORM CBPG_PkgVariable$InitValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan2_', EAPG_SichosonKisoFileT$FukaGendoSisan2_);

        PERFORM CBPG_PkgVariable$InitValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan_', EAPG_SichosonKisoFileT$FukaGendoSisan_);

        PERFORM CBPG_PkgVariable$InitValue('EAPG_SichosonKisoFileT', 'Write_Flg', EAPG_SichosonKisoFileT$Write_Flg);

        -- 処理開始ジャーナル
        PERFORM CCPG_BATCHJOURNALWRITER$PRC_WriteProcBlockStart(concat('　' , /*THIS_PROC_BLOCK*/'賦課限度額控除後試算ワーク作成'));

        lFukaNendo := pFukaNendo;
        lSikakuKijunYmd := CBPG_DATE$FNC_GetCurrentYMD();

        lrec := EAPG_SichosonKisoFileT$GetKeisanParam(lFukaNendo, pKankatuCd);
        lFukaNendo = lrec.pfukanendo;
        -- 計算パラメータ取得処理
        IF lrec.pRet = /*RETURN_FALSE*/1 THEN
            lErrMsg := '　賦課計算用パラメータを取得できなかったため、処理を終了しました。';
            PERFORM CCPG_BATCHJOURNALWRITER$PRC_WriteFreeError(lErrMsg);
            RETURN /*RETURN_FALSE*/1;
        END IF;

        DECLARE
            -- 資格基準年月日時点での、資格対象世帯を抽出するカーソル
            csrSetai CURSOR FOR
                SELECT DISTINCT T2.KokuhoNo
                              , T2.KokuhoRNo
                              , T2.SetainusiNo
                           -- @us 25/11/28 RG-EA-25-0071 各種一覧等のレスポンス改善
                           FROM (SELECT T1.KokuhoNo
                                      , MAX(T1.KokuhoRNo) KokuhoRNo
                                   FROM EATB_SikakuDRireki T1
                                        INNER JOIN EATB_IdoTdk T2
                                           ON T1.IdoNo = T2.IdoNo
                                  WHERE ((     T2.TdkYmd <= makieya.dateadd(lSikakuKijunYmd, 1)
                                           AND T2.IdoYmd <= makieya.dateadd(lSikakuKijunYmd, 1) AND T2.IDOJIYUCD IN (/*JIYUCD_SKANYU*/32, /*JIYUCD_KKANYU*/35, /*JIYUCD_SNINTEI*/36)) OR
                                         ( T2.TdkYmd <= lSikakuKijunYmd
                                          AND T2.IdoYmd <= lSikakuKijunYmd AND T2.IDOJIYUCD NOT IN (/*JIYUCD_SKANYU*/32, /*JIYUCD_KKANYU*/35, /*JIYUCD_SNINTEI*/36)))
                                  GROUP BY T1.KokuhoNo)       V1
                                INNER JOIN EATB_SikakuDRireki T1 ON  V1.KokuhoNo  = T1.KokuhoNo
                                                                 AND V1.KokuhoRNo = T1.KokuhoRNo
                                INNER JOIN EATB_NusiRireki    T2 ON  T1.KokuhoNo  = T2.KokuhoNo
                                                                 AND T1.KokuhoRNo = T2.KokuhoRNo
                          WHERE T2.GaitoYmd  <= lSikakuKijunYmd
                           -- @ue 25/11/28 RG-EA-25-0071
                            AND (   T2.HiGaitoYmd > lSikakuKijunYmd
                                 OR makieya.isEmpty(T2.HiGaitoYmd) = TRUE )
                            AND (   (pKankatuCd  = -1)
                                 OR (pKankatuCd != -1 AND T1.KankatuCd = pKankatuCd))
                          ORDER BY T2.KokuhoNo
                                 , T2.KokuhoRNo
                                 , T2.SetainusiNo;
        BEGIN
            lNmlCnt := 0;
            lSetaiCnt := 0;

            EAPG_SichosonKisoFileT$FukaGendoSisan2_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan2_', EAPG_SichosonKisoFileT$FukaGendoSisan2_);
            EAPG_SichosonKisoFileT$FukaGendoSisan_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan_', EAPG_SichosonKisoFileT$FukaGendoSisan_);

            FOR recSetai IN csrSetai LOOP

                lParam  := concat('賦課年度:' , pFukaNendo , ',国保番号:' , recSetai.KokuhoNo  , ',世帯主番号:' , recSetai.SetainusiNo);

                FOR i IN /*EAPG_Cnst.UTIWAKE_G*/1 .. /*EAPG_Cnst.UTIWAKE_KD*/11 LOOP
                    -- 賦課限度額控除後試算ワーク作成情報２ 初期化
                    EAPG_SichosonKisoFileT$FukaGendoSisan2_[i] := NULL;
                    item = EAPG_SichosonKisoFileT$FukaGendoSisan2_[i];
                    item.FukaNendo   := pFukaNendo;
                    item.KokuhoNo    := recSetai.KokuhoNo;
                    item.SetainusiNo := recSetai.SetainusiNo;
                    item.UtiwakeKbn  := i;
                    CALL EAPG_SichosonKisoFileT$InitFukaGendoSisan(item);
                    EAPG_SichosonKisoFileT$FukaGendoSisan2_[i] = item;

                    FOR j IN /*EAPG_Cnst.IDX_APR1*/0 .. /*EAPG_Cnst.IDX_MAR*/12 LOOP
                        -- 賦課限度額控除後試算ワーク作成情報 初期化
                        EAPG_SichosonKisoFileT$FukaGendoSisan_R[j]  := NULL;
                        item = EAPG_SichosonKisoFileT$FukaGendoSisan_R[j];
                        item.FukaNendo   := pFukaNendo;
                        item.KokuhoNo    := recSetai.KokuhoNo;
                        item.SetainusiNo := recSetai.SetainusiNo;
                        item.UtiwakeKbn  := i;
                        CALL EAPG_SichosonKisoFileT$InitFukaGendoSisan(item);
                        EAPG_SichosonKisoFileT$FukaGendoSisan_R[j] = item;
                        EAPG_SichosonKisoFileT$FukaGendoSisanT.TIXSisan := EAPG_SichosonKisoFileT$FukaGendoSisan_R;
                        EAPG_SichosonKisoFileT$FukaGendoSisan_[i] = EAPG_SichosonKisoFileT$FukaGendoSisanT;
                    END LOOP;
                END LOOP;

                PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan_' , EAPG_SichosonKisoFileT$FukaGendoSisan_);
                PERFORM CBPG_PkgVariable$SetValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan2_', EAPG_SichosonKisoFileT$FukaGendoSisan2_);

                -- 資格加入情報取得処理
                lrec := EAPG_SichosonKisoFileT$NewSikakuFuka(pFukaNendo,
                                       recSetai.KokuhoNo,
                                       recSetai.KokuhoRNo,
                                       recSetai.SetainusiNo,
                                       lSikakuKijunYmd);
                lRet1 = lrec.pRet;
                lCnt = lrec.pcnt;

                IF lRet1 = /*RETURN_FALSE*/1 THEN
                    -- ワーニングメッセージ出力
                    lErrMsg := '資格加入情報取得処理においてエラーが発生しました。';
                    PERFORM CCPG_BATCHWARNJOURNALWRITER$PRC_WriteWarn(lParam, /*THIS_PROC_BLOCK*/'賦課限度額控除後試算ワーク作成', lErrMsg);

                END IF;

                IF lRet1 = /*RETURN_TRUE*/0 THEN
                    -- 賦課試算処理
                    lrec := EAPG_SichosonKisoFileT$FukaSisan(pFukaNendo,
                                       pKanKatuCd,
                                       recSetai.KokuhoNo,
                                       recSetai.KokuhoRNo,
                                       recSetai.SetainusiNo,
                                       lCnt - 1);
                    lRet2 = lrec.pRet;
                    lKeigenKbn = lrec.pkeigenkbn;

                    IF lRet2 = /*RETURN_FALSE*/1 THEN
                        -- ワーニングメッセージ出力
                        lErrMsg := '賦課試算処理においてエラーが発生しました。';
                        PERFORM CCPG_BATCHWARNJOURNALWRITER$PRC_WriteWarn(lParam, /*THIS_PROC_BLOCK*/'賦課限度額控除後試算ワーク作成', lErrMsg);

                    END IF;

                    IF lRet2 = /*RETURN_TRUE*/0 THEN
                        EAPG_SichosonKisoFileT$Write_Flg = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'Write_Flg', EAPG_SichosonKisoFileT$Write_Flg);
                        -- 賦課限度額控除後試算ワーク作成情報設定
                        FOR i IN /*EAPG_Cnst.UTIWAKE_IG*/2 .. /*EAPG_Cnst.UTIWAKE_KD*/11 LOOP
                            -- 書き込みフラグが1の場合
                            IF EAPG_SichosonKisoFileT$Write_Flg[i] = 1 THEN

                                -- 賦課限度額控除後試算ワーク作成処理
                                EAPG_SichosonKisoFileT$FukaGendoSisan2_ = CBPG_PkgVariable$GetValue('EAPG_SichosonKisoFileT', 'FukaGendoSisan2_', EAPG_SichosonKisoFileT$FukaGendoSisan2_);
                                IF EAPG_SichosonKisoFileT$NewSisanWork(EAPG_SichosonKisoFileT$FukaGendoSisan2_[i]) = /*RETURN_FALSE*/1 THEN
                                    -- ワーニングメッセージ出力
                                    lErrMsg := '賦課限度額控除後試算ワークのデータ更新においてエラーが発生しました。';
                                    PERFORM CCPG_BATCHWARNJOURNALWRITER$PRC_WriteWarn(lParam, /*THIS_PROC_BLOCK*/'賦課限度額控除後試算ワーク作成', lErrMsg);

                                ELSE
                                    -- 正常更新カウントをカウントアップ
                                    lNmlCnt := lNmlCnt + 1;
                                END IF;
                            END IF;
                        END LOOP;
                    END IF;
                END IF;

                -- 処理経過ジャーナル
                lSetaiCnt := lSetaiCnt + 1;
                PERFORM CCPG_BATCHJOURNALWRITER$PRC_WriteProcBlockProsessing(concat('　　' , /*THIS_PROC_BLOCK*/'賦課限度額控除後試算ワーク作成'), lSetaiCnt::integer);
            END LOOP;

            -- 処理結果ジャーナル
            IF lSetaiCnt > 0 THEN
                -- 作成終了ジャーナル
                PERFORM CCPG_BATCHJOURNALWRITER$PRC_WriteProcBlockResult(concat('　' , /*THIS_PROC_BLOCK*/'賦課限度額控除後試算ワーク作成'), lSetaiCnt::integer);
            ELSE
                -- 作成対象データ無しジャーナル
                PERFORM CCPG_BATCHJOURNALWRITER$PRC_WriteProcBlockNoData(concat('　' , /*THIS_PROC_BLOCK*/'賦課限度額控除後試算ワーク作成'));
            END IF;

            -- 処理終了ジャーナル
            PERFORM CCPG_BATCHJOURNALWRITER$PRC_WriteProcBlockFinish(concat('　' , /*THIS_PROC_BLOCK*/'賦課限度額控除後試算ワーク作成'));

            -- 市町村基礎ファイル（退職保険料・保険料軽減額）ワーク作成処理
            IF EAPG_SichosonKisoFileT$NewSichosonFileTWork(pFukaNendo, pKankatuCd) = /*RETURN_FALSE*/1 THEN
                lParam  := concat('賦課年度:' , pFukaNendo , ',管轄コード:' , pKankatuCd);
                -- ワーニングメッセージ出力
                lErrMsg := '市町村基礎ファイル（退職保険料・保険料軽減額）ワークのデータ更新においてエラーが発生しました。';
                PERFORM CCPG_BATCHJOURNALWRITER$PRC_WriteFreeError(lErrMsg);
                RETURN /*RETURN_FALSE*/1;

            ELSE
                -- 正常更新カウントをカウントアップ
                lNmlCnt := lNmlCnt + 1;
            END IF;

        END;

        -- 処理結果ジャーナル
        IF lSetaiCnt > 0 THEN
            -- 作成終了ジャーナル
            PERFORM CCPG_BATCHJOURNALWRITER$PRC_WriteProcBlockResult(concat('　' , /*THIS_PROC_BLOCK2*/'市町村基礎ファイル（退職保険料・保険料軽減額）作成ワーク作成'), lSetaiCnt::integer);
        ELSE
            -- 作成対象データ無しジャーナル
            PERFORM CCPG_BATCHJOURNALWRITER$PRC_WriteProcBlockNoData(concat('　' , /*THIS_PROC_BLOCK2*/'市町村基礎ファイル（退職保険料・保険料軽減額）作成ワーク作成'));
        END IF;

        -- 処理終了ジャーナル
        PERFORM CCPG_BATCHJOURNALWRITER$PRC_WriteProcBlockFinish(concat('　' , /*THIS_PROC_BLOCK2*/'市町村基礎ファイル（退職保険料・保険料軽減額）作成ワーク作成'));

        RETURN /*RETURN_TRUE*/0;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS SQLCODE = RETURNED_SQLSTATE;
            lErrMsg := concat(/*THIS_PACKAGE*/'EAPG_SichosonKisoFileT' , '.FNC_SichosonKisoFileT:' , SQLCODE , ' ' , SQLERRM , ' ');
            CALL CBPG_ERRLOG$PRC_Logging(lErrMsg);
            PERFORM makieya.RAISE_APPLICATION_ERROR('EA900', lErrMsg, TRUE);

    END;

$$ LANGUAGE plpgsql;

