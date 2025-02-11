/******************************************
 * 网上国网🌏
 *****************************************
 修改适配homeassistant，通过mqtt发送消息至homeassistant
 CHANGES: 去除无用环境验证
 SOURCE: https://github.com/x2rr/state-grid/blob/main/state-grid.js
 *****************************************
 环境变量设置
 export WSGW_USERNAME="" #网上国网账号
 export WSGW_PASSWORD="" #网上国网密码
 export WSGW_RECENT_ELC_FEE="true" #是否获取最近电费
 export WSGW_mqtt_host="" #mqtt服务器地址 192.168.1.7
 export WSGW_mqtt_port="" #mqtt服务器端口 1883
 export WSGW_mqtt_username="" #mqtt服务器用户名
 export WSGW_mqtt_password="" #mqtt服务器密码
 ******************************************/
class Logger {
  constructor(e = "日志输出", o = "info") {
    (this.prefix = e),
      (this.levels = ["trace", "debug", "info", "warn", "error"]),
      this.setLevel(o);
  }
  setLevel(e) {
    this.currentLevelIndex = this.levels.indexOf(e);
  }
  log(e, ...o) {
    this.levels.indexOf(e) >= this.currentLevelIndex &&
      console.log(
        `${this.prefix ? `[${this.prefix}] ` : ""}[${e.toUpperCase()}]\n` +
          [...o].join("\n")
      );
  }
  trace(...e) {
    this.log("trace", ...e);
  }
  debug(...e) {
    this.log("debug", ...e);
  }
  info(...e) {
    this.log("info", ...e);
  }
  warn(...e) {
    this.log("warn", ...e);
  }
  error(...e) {
    this.log("error", ...e);
  }
}
const request$1 = async (request = {} || "", option = {}) => {
  switch (request.constructor) {
    case Object:
      request = { ...request, ...option };
      break;
    case String:
      request = { url: request, ...option };
  }
  request.method ||
    ((request.method = "GET"),
    (request.body ?? request.bodyBytes) && (request.method = "POST")),
    delete request.headers?.["Content-Length"],
    delete request.headers?.["content-length"];
  const method = request.method.toLocaleLowerCase();
  const got = eval('require("got")');
  let iconv = eval('require("iconv-lite")');
  const { url: url, ...option } = request;
  return await got[method](url, option).then(
    (e) => (
      (e.statusCode = e.status),
      (e.body = iconv.decode(e.rawBody, request?.encoding || "utf-8")),
      (e.bodyBytes = e.rawBody),
      e
    ),
    (e) => {
      if (e.response && 500 === e.response.statusCode)
        return Promise.reject(e.response.body);
      Promise.reject(e.message);
    }
  );
};
class Store {
  constructor(NAMESPACE) {
    this.Store = NAMESPACE ? `./store/${NAMESPACE}` : "./store";
    const { LocalStorage } = require("node-localstorage");
    this.localStorage = new LocalStorage(this.Store);
  }
  get(key) {
    return this.localStorage.getItem(key);
  }
  set(key, value) {
    this.localStorage.setItem(key, value);
    return true;
  }
  clear(key) {
    this.localStorage.removeItem(key);
    return true;
  }
}
const notify = (e = "", o = "", r = "", s = {}) => {
    const n = (e) => {
      const { $open: o, $copy: r, $media: s, $mediaMime: n } = e;
      switch (typeof e) {
        case void 0:
          return e;
        case "string":
          return;
      }
    };
    let t = ["", "==============📣系统通知📣=============="];
    t.push(e), o && t.push(o), r && t.push(r), console.log(t.join("\n"));
  },
  done = (e = {}) => {
    process.exit(1);
  },
  SERVER_HOST = "https://api.120399.xyz",
  BASE_URL = "https://www.95598.cn",
  request = async (e) => {
    try {
      const o = {
          url: `${SERVER_HOST}/wsgw/encrypt`,
          headers: { "content-type": "application/json" },
          body: JSON.stringify({ yuheng: e }),
        },
        r = await Encrypt(o);
      switch (e.url) {
        case "/api/oauth2/oauth/authorize":
          Object.assign(r, { body: r.body.replace(/^\"|\"$/g, "") });
          break;
        case "/api/oauth2/outer/getWebToken":
          o.headers["content-type"] = "text/plain;charset=UTF-8";
      }
      let { body: s } = await request$1(r);
      try {
        s = JSON.parse(s);
      } catch {}
      if (
        s.code &&
        (10010 == s.code ||
          (10002 === s.code && "WEB渠道KeyCode已失效" == s.message) ||
          30010 === s.code ||
          "20103" === s.code ||
          (10002 === s.code && bizrt.token && "Token 为空！" == s.message))
      )
        return Promise.reject(s.message);
      const n = { config: { ...e }, data: s };
      if ("/api/oauth2/outer/c02/f02" === e.url)
        Object.assign(n.config, { headers: { encryptKey: r.encryptKey } });
      const t = {
        url: `${SERVER_HOST}/wsgw/decrypt`,
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ yuheng: n }),
      };
      return await Decrypt(t);
    } catch (e) {
      return Promise.reject(e);
    }
  },
  Encrypt = async (e) =>
    request$1(e).then(({ body: e }) => {
      try {
        e = JSON.parse(e);
      } catch {}
      return (
        (e.data.url = BASE_URL + e.data.url),
        (e.data.body = JSON.stringify(e.data.data)),
        delete e.data.data,
        e.data
      );
    }),
  Decrypt = async (e) =>
    request$1(e).then(({ body: o }) => {
      let r = JSON.parse(o);
      const { code: s, message: n, data: t } = r.data;
      return "" + s == "1"
        ? t
        : e.url.indexOf("oauth2/oauth/authorize") > -1 &&
            t &&
            s &&
            "" != s &&
            (10015 === s ||
              10108 === s ||
              10009 === s ||
              10207 === s ||
              10005 === s ||
              10010 === s ||
              30010 === s ||
              (10002 === s && "WEB渠道KeyCode已失效" == n) ||
              (10002 === s && bizrt.token && "Token 为空！" == n))
          ? Promise.reject(`重新获取: ${n}`)
          : Promise.reject(n);
    }),
  Recoginze = async (e) => {
    const o = {
      url: `${SERVER_HOST}/wsgw/get_x`,
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ yuheng: e }),
    };
    return request$1(o).then(({ body: e }) => JSON.parse(e));
  },
  getBeforeDate = (e) => {
    const o = new Date();
    o.setDate(o.getDate() - e);
    return `${o.getFullYear()}-${String(o.getMonth() + 1).padStart(
      2,
      "0"
    )}-${String(o.getDate()).padStart(2, "0")}`;
  },
  jsonParse = (e) => {
    try {
      return JSON.parse(e);
    } catch {
      return e;
    }
  },
  jsonStr = (e, ...o) => {
    if ("string" == typeof e) return e;
    try {
      return JSON.stringify(e, ...o);
    } catch {
      return e;
    }
  },
  isTrue = (e) => !0 === e || "true" === e || 1 === e || "1" === e,
  $api = {
    getKeyCode: "/oauth2/outer/c02/f02",
    getAuth: "/oauth2/oauth/authorize",
    getWebToken: "/oauth2/outer/getWebToken",
    getRoutes: "/osg-web0004/open/c7/f01",
    searchMenu: "/osg-web0004/open/c2/f02",
    contentSearch: "/osg-web0004/open/c4/f05",
    shouyequery: "/osg-web0004/member/c4/f08",
    seachOrgNo: "/osg-open-om0001/member/c13/f05",
    detailpcut: "/osg-open-mce0001/member/c4/f06",
    login: "/osg-open-uc0001/member/c8/f23",
    loginout: "/osg-open-uc0001/member/c8/f2311111",
    tokenlogin: "/osg-open-uc0001/member/c8/f01",
    seachMsgEs: "/osg-web0004/open/c4/f03",
    orderEmail: "/osg-open-bc0001/member/c02/f04",
    LowelectBill: "/osg-open-bc0001/member/c04/f01",
    HideelectBill: "/osg-open-bc0001/member/c04/f02",
    quantity: "/osg-open-bc0001/member/c01/f01",
    searchProgress: "/osg-open-uc0001/member/c6/f06",
    Urge: "/osg-open-woc0001/member/c5/f06",
    fileLists: "/osg-open-woc0001/member/c27/f01",
    fileLists2: "/osg-open-woc0001/member/c5/f07",
    fileLists3: "/osg-open-woc0001/member/c5/f08",
    realType: "/osg-open-uc0001/member/c7/f01",
    paymentRecord: "/osg-open-bc0001/member/c03/f12",
    power: "/osg-omgmt0005/member/c9/f30",
    accountInfo: "/osg-open-uc0001/member/c4/f01",
    address: "/osg-open-om0001/member/c72/f01",
    CheckBillAmount: "/osg-open-bc0001/member/c03/f07",
    vatname: "/osg-open-uc0001/member/c4/f02",
    fgd_Submit: "/osg-open-woc0001/member/c4/f09",
    fgd_appraise: "/osg-open-woc0001/member/c27/f07",
    shouye: "/osg-web0004/open/c1/f01",
    captcha: "/osg-web0004/open/c15/f01",
    login: "/osg-open-uc0001/member/c8/f23",
    captchaPassword: "/osg-web0004/open/c15/f03",
    getCode2: "/osg-web0004/open/c50/f02",
    getCode: "/osg-open-uc0001/member/c8/f24",
    clickCard: "/osg-web0004/open/c44/f07",
    useTokenGetInfo: "/osg-uc0013/member/c4/f04",
    tokenGetUserInfo: "/osg-open-uc0001/member/c8/f56",
    getQCodeNew: "/osg-open-uc0001/member/c8/f31",
    checkQCode: "/osg-open-uc0001/member/c8/f32",
    qcodeCallback: "/osg-open-uc0001/member/c8/f33",
    content: "/osg-web0004/open/c4/f01",
    menu: "/osg-web0004/open/c2/f01",
    indexPage: "/osg-web0004/open/c1/f01",
    newsList: "/osg-open-mce0001/member/c4/f01",
    delMsg: "/osg-open-mce0001/member/c4/f05",
    codeLogin: "/osg-open-uc0001/member/c8/f22",
    codeLoginApi: "/osg-uc0013/member/c4/f02",
    reg: "/osg-open-uc0001/member/c8/f25",
    dianfeiList: "/osg-open-bc0001/member/c01/f02",
    changePassword: "/osg-open-uc0001/member/c8/f06",
    Presubmission: "/osg-open-woc0001/member/c4/f03",
    messageList: "/osg-open-uc0001/member/c13/f01",
    newMessageList: "/osg-web0004/member/c15/f06",
    forgetPass: "/osg-open-uc0001/member/c8/f06",
    sendCode: "/osg-open-uc0001/member/c8/f04",
    checkCode: "/osg-open-uc0001/member/c8/f05",
    resetPass: "/osg-open-uc0001/member/c8/f07",
    submitHouse: "/osg-open-uc0001/member/c5/f04",
    bindholds: "/osg-open-uc0001/member/c14/f02",
    getBindDoorCity: "/osg-open-om0001/member/arg/020390006",
    hadList: "/osg-open-uc0001/member/c9/f02",
    holdList: "/osg-open-uc0001/member/c9/f03",
    wantbindhold: "/osg-open-uc0001/member/c9/f04",
    holdsign: "/osg-open-uc0001/member/c9/f07",
    Mainhold: "/osg-open-uc0001/member/c9/f05",
    untying: "/osg-open-uc0001/member/c14/f03",
    holdCert: "/osg-open-uc0001/member/c5/f02",
    onSite: "/osg-open-woc0001/member/c27/f20",
    subJudge: "/osg-open-sfan0001/member/c4/f01",
    getevalMsg: "/osg-open-om0001/member/c8/f02",
    getVCommit: "/osg-open-sfan0001/member/c4/f02",
    pauseSCode: "/osg-open-woc0001/member/c27/f30",
    newSCode: "/osg-web0004/member/c15/f05",
    pauseTCode: "/osg-open-woc0001/member/c27/f24",
    giveHome: "/osg-open-woc0001/member/c4/f13",
    reName: "/osg-open-woc0001/member/c4/f12",
    uploadPic: "/osg-open-scp0001/member/c5/f05",
    uploadAuthPic: "/osg-open-scp0001/member/c5/f07",
    invoiceList: "/osg-open-bc0001/member/c02/f01",
    operaLis: "/osg-open-bc0001/member/c02/f03",
    kpdetailsLis: "/osg-open-bc0001/member/c02/f02",
    unread: "/osg-open-mce0001/member/c4/f02",
    readAllMsg: "/osg-open-mce0001/member/c4/f07",
    markRead: "/osg-open-mce0001/member/arg/010410001",
    newsdetails: "/osg-open-mce0001/member/c4/f04",
    newsdelete: "/osg-open-mce0001/member/c4/f05",
    pay: "/osg-wp0004/member/payment/getPayMethodList",
    createOrder: "/osg-wp0002/member/charge/createOrder",
    invokey: "/osg-wp0002/member/charge/invokePay",
    surplus: "/osg-wp0002/member/charge/getElecUserChargeList",
    orderStatus: "/osg-wp0002/member/charge/getOrderHeaderStatus",
    reCardVer: "/osg-wp0002/member/charge/checkRechargeUser",
    reCardRecharge: "/osg-wp0002/member/charge/rechargeCard",
    searchUser: "/osg-open-uc0001/member/c9/f02",
    send: "/osg-open-uc0001/member/c8/f04",
    code: "/osg-open-uc0001/member/c8/f05",
    electBill: "/osg-open-bc0001/member/c04/f03",
    segmentDate: "/osg-open-bc0001/member/arg/020070013",
    Progress: "/osg-web0004/member/c18/f01",
    searchProgress2: "/osg-open-uc0001/member/c6/f07",
    lookMore: "/osg-open-uc0001/member/c6/f02",
    gdAnniu: "/osg-open-woc0001/member/c27/f19",
    deleteProgress: "/osg-open-uc0001/member/c6/f05",
    dataList: "osg-open-woc0001/member/c27/f16",
    dataList2: "osg-open-woc0001/member/c27/f17",
    getData: "/osg-open-woc0001/member/c27/f28",
    getOtherData: "/osg-open-woc0001/member/arg/020370031",
    startData: "/osg-open-woc0001/member/c27/f27",
    complaintsubmit: "/osg-open-woc0001/member/c5/f00",
    reportsubmit: "/osg-open-woc0001/member/c5/f01",
    professionsubmit: "/osg-open-woc0001/member/c5/f02",
    havesaysubmit: "/osg-open-woc0001/member/c5/f03",
    faultrepairsubmit: "/osg-open-woc0001/member/c5/f04",
    faultrepair: "/osg-open-om0001/member/c72/f02",
    idauthen: "/osg-open-woc0001/member/c27/f26",
    companySub: "/osg-open-woc0001/member/c4/f07",
    increaseSub: "/osg-open-woc0001/member/c4/f10",
    subzj: "/osg-open-woc0001/member/c4/f06",
    order: "/osg-open-scp0001/member/c4/f01",
    vatchang: "/osg-open-woc0001/member/c4/f17",
    doorNumber: "/osg-open-uc0001/member/c9/f02",
    setMainDoor: "/osg-open-uc0001/member/c9/f05",
    queryAbleBindDoorNumber: "/osg-open-uc0001/member/c9/f03",
    identitySubmit: "/osg-open-uc0001/member/c8/f02",
    listconsumers: "/osg-open-uc0001/member/c6/f03",
    delListconsumers: "/osg-open-uc0001/member/arg/020360024",
    listconsumers_Progress: "/osg-open-uc0001/member/c6/f01",
    stopCapacity: "/osg-open-woc0001/member/c4/f01",
    lessCapacity: "/osg-open-woc0001/member/c4/f02",
    personageApi: "/osg-open-woc0001/member/c4/f11",
    newHouseholdElectricity: "/osg-open-woc0001/member/c4/f08",
    certificationSearchFinal: "/osg-open-uc0001/member/c8/f11",
    identitymap: "/osg-open-uc0001/member/c8/f08",
    OCR: "/osg-open-uc0001/member/c8/f09",
    adFlag: "/osg-open-uc0001/member/c14/f01",
    meterCalibration: "/osg-open-woc0001/member/c4/f05",
    meteringPoint: "/osg-open-uc0001/member/c6/f11",
    transformer: "/osg-open-uc0001/member/c6/f08",
    powerSupply: "/osg-open-uc0001/member/c6/f10",
    updateUserInfo: "/osg-open-uc0001/member/c8/f03",
    updateAccount: "/osg-open-uc0001/member/c8/f26",
    userInfo: "/osg-open-uc0001/member/c8/f01",
    pauseSub: "/osg-open-woc0001/member/c4/f15",
    reduceSub: "/osg-open-woc0001/member/c4/f16",
    infoSupplement: "/osg-open-woc0001/member/c27/f25",
    electricityPriceStrategyChange: "/osg-open-woc0001/member/arg/030340052",
    subscriptionList: "/osg-open-mce0001/member/c7/f00",
    participate: "/osg-open-mce0001/member/c05/f04",
    fuzzySearch: "/osg-open-uc0001/member/c4/f04",
    downloadImg: "/osg-open-scp0001/member/c5/f02",
    tokendownloadImg: "/osg-open-uc0001/member/c8/f72",
    eemandValueAdjustment: "/osg-open-woc0001/member/c4/f14",
    oneOffice: "/osg-open-scp0001/member/c4/f02",
    ceshi: "/osg-rm0001/member/c1/f05",
    InformationConfirmation: "/osg-open-woc0001/member/c27/f21",
    vatlist: "/osg-open-om0001/member/c72/f03",
    payAmtList: "/osg-web0004/member/c77/f01",
    accapi: "/osg-open-bc0001/member/c05/f01",
    chergileApi: "/osg-open-woc0001/member/c4/f04",
    otherApi: "/osg-open-woc0001/member/c27/f40",
    demographicStatus: "/osg-open-sfan0001/member/c5/f01",
    demoGraphicChecks: "/osg-open-sfan0001/member/c5/f03",
    subDemoGraphic: "/osg-woc0001/member/c72/f01",
    checkHomeApi: "/osg-open-sfan0001/member/c5/f02",
    biaojiDanHao: "/osg-open-uc0001/member/c6/f09",
    electTrend: "/osg-open-bc0001/member/c03/f14",
    dayElectLoad: "/osg-open-bc0001/member/c03/f05",
    electLoadTrend: "/osg-open-bc0001/member/c03/f06",
    JiFen: "/osg-open-om0001/member/c19/f01",
    JiFenYuE: "/osg-open-om0001/member/c19/f02",
    searchBankBind: "/osg-open-uc0001/member/c8/f18",
    hasBindBankAuth: "/osg-open-uc0001/member/c8/f20",
    bankAuthSendCode: "/osg-open-uc0001/member/c8/f16",
    HBankAuthCode: "/osg-open-uc0001/member/c8/f15",
    searchBankXY: "/osg-open-uc0001/member/c8/f14",
    searchIDofBank: "/osg-open-uc0001/member/c8/f13",
    searchTypeOfBank: "/osg-open-uc0001/member/c8/f12",
    boundsendver: "/osg-open-uc0001/member/c8/f21",
    friendLink: "/osg-web0004/open/c5/f01",
    getIPAddr: "/osg-web0004/open/c8/f01",
    pauseSCodeApi: "/osg-open-woc0001/member/c27/f30",
    checkCodeApi: "/osg-woc0001/member/c2/f01",
    payCodeApi: "/osg-open-uc0001/member/arg/030010192",
    empowerBindApi: "/osg-open-uc0001/member/arg/030010193",
    getAuthToken: "/osg-open-uc0001/member/arg/020360047",
    getUserInfoByAuthToken: "/osg-open-uc0001/member/arg/020360048",
    loginVerifyCode: "/osg-web0004/open/c44/f01",
    loginTestCode: "/osg-web0004/open/c44/f02",
    loginVerifyCodeNew: "/osg-web0004/open/c44/f05",
    loginTestCodeNew: "/osg-web0004/open/c44/f06",
    jsonApi: "/osg-web0004/member/c15/f01",
    getNewsApi: "/osg-web0004/open/c4/f04",
    getBankInfo: "/osg-open-uc0001/member/c8/f17",
    newsListApi: "/osg-web0004/member/c15/f02",
    StopList: "/osg-open-mce0001/member/c06/f01",
    busInfoApi: "/osg-web0004/member/c24/f01",
    getIntelligentPaymentStatus: "/osg-open-bc0001/member/arg/020070032",
    getnewPhoneCode: "/osg-web0004/member/c15/f03",
    allFileLists: "/osg-web0004/member/c24/f02",
    changePhoneGetOldCode: "/osg-web0004/member/c15/f04",
    emergencys: "/osg-open-p0001/member/c5/f03",
    theme: "/osg-web0004/open/c3/f01",
    backOrderMsg: "/osg-woc0001/member/c70/f01",
    queryCarAddress: "/osg-web0004/member/c49/f01",
    queryBoundGroupAccount: "/osg-open-uc0001/member/arg/030360248",
    queryBoundGroupSubAccount: "/osg-open-uc0001/member/arg/030360252",
    queryElectricEnterprise: "/osg-open-bc0001/member/arg/030070112",
    queryAccountNumberBoundEnterprise: "/osg-open-bc0001/member/arg/030070112",
    queryapUPConsumingEnterprises: "/osg-open-bc0001/member/arg/030070113",
    queryPowerHandlingProcess: "/osg-open-woc0001/member/arg/030010214",
    getAppaVersion: "/osg-web0004/open/c17/f01",
    homeMsgBox: "/osg-web0004/open/c18/f01",
    excludeDayCompany: "/osg-open-bc0001/member/c11/f04",
    excludeDayUser: "/osg-open-bc0001/member/c11/f03",
    excludeMonthCompany: "/osg-open-bc0001/member/c11/f02",
    excludeMonthUser: "/osg-open-bc0001/member/c11/f01",
    eleMonthForecast: "/osg-open-bc0001/member/c11/f00",
    eleMonthRange: "/osg-open-bc0001/member/c10/f14",
    eleMonthRangePermit: "/osg-open-bc0001/member/c10/f16",
    eleDayRange: "/osg-open-bc0001/member/c10/f17",
    eleDayRangePermit: "/osg-open-bc0001/member/c10/f19",
    ListAgentUsersElectricitySellingE: "/osg-open-uc0001/member/c9/f11",
    ListAuthorizeUsersElectricitySellingE: "/osg-open-sfan0001/member/c8/f03",
    BoundEnterpriseQuery: "/osg-open-uc0001/member/c9/f14",
    eleMonthThb: "/osg-open-bc0001/member/c10/f14",
    eleApplyCount: "/osg-open-bc0001/member/c11/f27",
    eleApplyCountChart: "/osg-open-bc0001/member/c11/f28",
    applyList: "/osg-open-bc0001/member/c11/f29",
    unApplyList: "/osg-open-bc0001/member/c11/f30",
    sendMessageByBatch: "/osg-open-bc0001/member/c11/f32",
    sendMessageByOne: "/osg-open-bc0001/member/c11/f31",
    exportApplyedData: "/osg-open-bc0001/member/c11/f56",
    priceDeviationData: "/osg-open-bc0001/member/c11/f52",
    priceDeviationTimeType: "/osg-open-bc0001/member/c11/f47",
    priceClearingCount: "/osg-open-bc0001/member/c11/f41",
    priceClearingList: "/osg-open-bc0001/member/c11/f42",
    priceClearingDelete: "/osg-open-bc0001/member/c11/f45",
    priceClearingDetail: "/osg-open-bc0001/member/c11/f43",
    priceClearingUpdate: "/osg-open-bc0001/member/c11/f44",
    priceClearingImportExcel: "/osg-open-bc0001/member/c11/f46",
    getMetaRegionByFullId: "/osg-open-bc0001/member/c11/f48",
    getElecList: "/osg-open-bc0001/member/c11/f13",
    electDelete: "/osg-open-bc0001/member/c11/f15",
    electDetails: "/osg-open-bc0001/member/c11/f14",
    electSave: "/osg-open-bc0001/member/c11/f16",
    applyPageList: "/osg-open-bc0001/member/c11/f49",
    applyPageCount: "/tradeApplyCaseRq/findApplyCaseRqCount",
    applyCaseRqDetail: " /osg-open-bc0001/member/c11/f50",
    applyCaseRqList: "/osg-open-bc0001/member/c11/f51",
    applyCaseRqSave: "/osg-open-bc0001/member/c11/f53",
    applyCaseRqDel: "/osg-open-bc0001/member/c11/f54",
    doHourCompanyFourcast: "/osg-open-bc0001/member/c11/f06",
    doSaveHourFourcast: " /osg-open-bc0001/member/c11/f07",
    getHourFourcastTasklist: "/osg-open-bc0001/member/c11/f08",
    getHourFourcastResultOneday: "/osg-open-bc0001/member/c11/f55",
    getHourFourcastResultByRefId: "/osg-open-bc0001/member/c11/f10",
    deleteHourFourcastResultByRefId: "/osg-open-bc0001/member/c11/f11",
    getDivisionByProviceCode: "/osg-open-bc0001/member/c11/f12",
    tCsaveTrade: "/osg-open-bc0001/member/c11/f33",
    tCsetMealList: "/osg-open-bc0001/member/c11/f34",
    tCdeleteOneById: "/osg-open-bc0001/member/c11/f35",
    tCgetTcDetailListByTcId: "/osg-open-bc0001/member/c11/f38",
    eleApplyList: "/osg-open-bc0001/member/c11/f23",
    eleApplyOne: "/osg-open-bc0001/member/c11/f24",
    eleApplySave: "/osg-open-bc0001/member/c11/f22",
    eleApplyModify: "/osg-open-bc0001/member/c11/f26",
    priceCatPrcQueryBySecNoAndProvince: "/osg-open-bc0001/member/c11/f20",
    priceCatPrcSave: "/osg-open-bc0001/member/c11/f21",
    priceCatPrcQueryForecastData: "/osg-open-bc0001/member/c11/f18",
    priceCatPrcGetBySecNo: "/osg-open-bc0001/member/c11/f17",
    priceCatPrcQueryElecHourData: "/osg-open-bc0001/member/c11/f19",
    applyDeviAnalyQuery: "/osg-open-bc0001/member/c11/f05",
    goodsSaveData: "/osg-open-bc0001/member/arg/030070085",
    goodsqueryList: "/osg-open-bc0001/member/arg/030070086",
    getDataByGoodsId: "/osg-open-bc0001/member/arg/030070087",
    goodsDelete: "/osg-open-bc0001/member/arg/030070088",
    goodsUpShelf: "/osg-open-bc0001/member/arg/030070089",
    goodsOffShelf: "/osg-open-bc0001/member/arg/030070090",
    goodsUploadFile: "/osg-open-bc0001/member/c11/f57",
    goodsDownloadFile: "/osg-open-bc0001/member/c11/f59",
    uploadFile: "/osg-open-bc0001/member/c11/f57",
    fileList: "/osg-open-bc0001/member/arg/030070083",
    downloadFileList: "/osg-open-bc0001/member/c11/f59",
    downloadFile: "/osg-open-bc0001/member/c11/f58",
    deleteFileById: "/osg-open-bc0001/member/arg/030070084",
    ordersList: "/osg-open-bc0001/member/arg/030210002",
    ordersDetail: "/osg-open-bc0001/member/arg/030070100",
    saveHtMain: "/osg-open-bc0001/member/arg/030070101",
    queryHtMainByOrderId: "/osg-open-bc0001/member/arg/030070102",
    comboOrdersApplyCancel: "/osg-open-bc0001/member/arg/030070092",
    comboOrdersConfirmCancel: "/osg-open-bc0001/member/arg/030070093",
    getFavList: "/osg-open-bc0001/member/arg/030070081",
    cancelFav: "/osg-open-bc0001/member/arg/030070080",
    saveFav: "/osg-open-bc0001/member/arg/030070079",
    ifFav: "/osg-open-bc0001/member/arg/030070082",
    queryEnquiryPageList: "/osg-open-bc0001/member/arg/030070095",
    goodsEnquirySaveData: "/osg-open-bc0001/member/arg/030070094",
    saveReplyEnquiryData: "/osg-open-bc0001/member/arg/030070099",
    goodsEnquiryList: "/osg-open-bc0001/member/arg/030070095",
    goodsComboordersCreate: "/osg-open-bc0001/member/arg/030070091",
    goodsComboordersJudgeQualifications:
      "/osg-open-bc0001/member/arg/030070098",
    goodsEnquiryOfferPriceJudge: "/osg-open-bc0001/member/arg/030070096",
    goodsEnquiryOfferPrice: "/osg-open-bc0001/member/arg/030070097",
    goodsEnquiryOffShelf: "/osg-open-bc0001/member/arg/030070105",
    queryDataListByEnquiryVo: "/osg-open-bc0001/member/arg/030070106",
    queryEnquiryListPage: "/osg-open-bc0001/member/arg/030070107",
    saveBackEnquiryData: "/osg-open-bc0001/member/arg/030070108",
    enquiryOrdersApplyCancel: "/osg-open-bc0001/member/arg/030070109",
    enquiryOrdersConfirmCancel: "/osg-open-bc0001/member/arg/030070110",
    saveFiles: "/osg-open-bc0001/member/arg/030070111",
    BindingOfElectricitySellingEnterprises: "/osg-open-uc0001/member/c9/f24",
    BindEnterprise: "/osg-open-uc0001/member/c8/f60",
    BoundEnterpriseQuery: "/osg-open-uc0001/member/c9/f14",
    ListAgentUsersElectricitySellingE: "/osg-open-uc0001/member/c9/f11",
    getSDCode: "/osg-open-uc0001/member/c8/f04",
    excludeDayCompany: "/osg-open-bc0001/member/c11/f04",
    excludeDayUser: "/osg-open-bc0001/member/c11/f03",
    excludeMonthCompany: "/osg-open-bc0001/member/c11/f02",
    excludeMonthUser: "/osg-open-bc0001/member/c11/f01",
    queryHandlerManagement: "/osg-open-sfan0001/member/arg/030330101",
    handlerPhoneCheck: "/osg-open-sfan0001/member/arg/030330102",
    getBindHandlerCode: "/osg-open-uc0001/member/arg/030360273",
    cancelHandlerBind: "/osg-open-sfan0001/member/arg/030330103",
    infoPublic: "/osg-omgmt1015/content/c01/f52",
    electrovalenceStandard: "/osg-omgmt1030/priceinfo/c01/f04",
    electrovalenceType: "/osg-omgmt1030/priceinfo/c01/f05",
    classicCase: "/osg-omgmt1030/content/c01/f52",
    uploadfile: "/osg-scp0002/member/c2/f03",
    dispute: "/osg-open-woc0001/member/c27/f52",
    disputeDetail: "/osg-open-woc0001/member/c27/f53",
    selldispite: "/osg-open-woc0001/member/c27/f51",
    information: "/osg-open-om0001/member/c16/f02",
    informationList: "/osg-open-om0001/member/c16/f03",
    searchKeyWords: "/osg-open-om0001/member/arg/020390035",
    searchKeyWordsInfo: "emss-pfa-pro-front/app_api/selectNewChannelist",
    billingService: "/osg-open-bc0001/member/c10/f01",
    monthSearch: "/osg-open-bc0001/member/c03/f15",
    dataSearch: "/osg-open-bc0001/member/c03/f16",
    pointSearch: "/osg-open-bc0001/member/c03/f17",
    indicatSearch: "/osg-open-bc0001/member/c03/f18",
    indicatPost: "/osg-open-bc0001/member/c03/f19",
    querySuperAdministrator: "/osg-open-sfan0001/member/arg/030010096",
    applySuperAdministrator: "/osg-open-sfan0001/member/arg/030330099",
    getApplicationRecord: "/osg-open-sfan0001/member/arg/030330100",
    fileUpload: "/osg-open-sfan0001/member/arg/030010098",
    fileDownload: "/osg-open-sfan0001/member/arg/030010097",
    querySellerPageList: "/osg-open-sfan0001/member/arg/030010182",
    querySettlePageList: "/osg-open-sfan0001/member/arg/030010183",
    elecYdPuPageList: "/osg-open-sfan0001/member/arg/030010178",
    elecYdPuConfirm: "/osg-open-sfan0001/member/arg/030010179",
    elecYdPuExport: "/saler/dldl/export",
    elecSbFdSaveSwdl: "/osg-open-sfan0001/member/arg/030010180",
    elecSbFdGetSwdl: "/osg-open-sfan0001/member/arg/030010181",
    salerDldjPageList: "/osg-open-sfan0001/member/arg/030010173",
    salerDldjConfirm: "/osg-open-sfan0001/member/arg/030010174",
    salerDldjSave: "/osg-open-sfan0001/member/arg/030010175",
    salerDldjImport: "/osg-open-sfan0001/member/arg/030010176",
    salerDldjExport: "/osg-open-sfan0001/member/arg/030010177",
    unbindPowerGenerationEnterprise: "/osg-open-uc0001/member/arg/030360278",
    queryPowerGenerationEnterpriseList: "/osg-open-uc0001/member/arg/030360279",
    bindPowerGenerationEnterprise: "/osg-open-uc0001/member/arg/030360280",
    queryBoundPowerGenerationEnterpriseList:
      "/osg-open-uc0001/member/arg/030370095",
    queryPowerGenerationEnterpriseDetail:
      "/osg-open-uc0001/member/arg/030360281",
    downloadNewGenFile: "/osg-open-bc0001/member/arg/020010002",
    downloadNewGenFile: "/osg-open-bc0001/member/arg/020010002",
    unbindPowerGenerationEnterprise: "/osg-open-uc0001/member/arg/030360278",
    queryPowerGenerationEnterpriseList: "/osg-open-uc0001/member/arg/030360279",
    bindPowerGenerationEnterprise: "/osg-open-uc0001/member/arg/030360280",
    queryBoundPowerGenerationEnterpriseList:
      "/osg-open-uc0001/member/arg/030370095",
    queryPowerGenerationEnterpriseDetail:
      "/osg-open-uc0001/member/arg/030360281",
    queryMonthElec: "/osg-open-bc0001/member/arg/020010008",
    queryMonthsElec: "/osg-open-bc0001/member/arg/020010010",
    queryDayElec: "/osg-open-bc0001/member/arg/020010009",
    queryDaysElec: "/osg-open-bc0001/member/arg/020010011",
    billPageList: "/osg-open-bc0001/member/arg/020010003",
    getBillById: "/osg-open-bc0001/member/arg/020010005",
    getMonthBillByMemberID: "/osg-open-bc0001/member/arg/020010004",
    getBillSummaryData: "/osg-open-bc0001/member/arg/020010007",
    submitBillData: "/osg-open-bc0001/member/arg/020010006",
    viewBindingAccountNumber: "/osg-open-uc0001/member/c9/f22",
    highVoltageSubscriberBinding: "/osg-open-uc0001/member/arg/020210008",
    saveGfPersonal: "/osg-open-om0001/member/arg/030010195",
    saveGfEnterprise: "/osg-open-om0001/member/arg/030010196",
    getGfOwnBankList: "/osg-open-om0001/member/arg/030010203",
    getGfAgentBankList: "/osg-open-om0001/member/arg/030010201",
    getGfBankList: "/osg-open-om0001/member/arg/030010205",
    changeGfBank: "/osg-open-om0001/member/arg/030010206",
    saveGfOwnBank: "/osg-open-om0001/member/arg/030010204",
    saveGfAgentBank: "/osg-open-om0001/member/arg/030010202",
    getGfPhoneCode: "/osg-open-om0001/member/arg/030010199",
    jointBusinessQuery: "/osg-open-woc0001/member/arg/030010211",
    jointBusinessSubmit: "/osg-open-woc0001/member/arg/030010212",
    sendSMS: "/osg-open-uc0001/member/c8/f48",
    getGBServiceList: "/osg-open-uc0001/member/arg/030360295",
    checkGBAccount: "/osg-open-uc0001/member/arg/030360297",
    GBEmpowerBind: "/osg-open-uc0001/member/arg/030360296",
    getStaticLink: "/osg-open-om0001/member/c11/f07",
    getBankDatainfo: "/osg-open-sfan0001/member/arg/010210042",
    labelsAccordingColumn: "/osg-web0004/open/c20/f01",
    getOurGradesConf: "/osg-web0004/open/c19/f01",
    subscribeInvoice: "/osg-open-bc0001/member/arg/030070148",
    emailSubscribe: "/osg-open-bc0001/member/arg/030070146",
    invoiceingEle: "/osg-open-bc0001/member/arg/030070144",
    invoiceListBj: "/osg-open-bc0001/member/arg/030070142",
    invoiceListZl: "/osg-open-bc0001/member/arg/030070149",
    invoicePrivate: "/osg-open-bc0001/member/arg/020070007",
    qurGcNoListNew: "/osg-open-woc0001/member/arg/020370033",
    getConfigInfo: "/osg-open-woc0001/member/arg/020370034",
    iphoneController: "/osg-open-woc0001/member/arg/020370035",
    selectElectricity: "/osg-open-woc0001/member/arg/020370038",
    selectPayScheduleNew: "/osg-open-woc0001/member/arg/020370039",
    payMessageFeedbackNew: "/osg-open-woc0001/member/arg/020370040",
    selectActualPaymentInfo: "/osg-open-woc0001/member/arg/020370041",
  },
  $configuration = {
    uscInfo: {
      member: "0902",
      devciceIp: "",
      devciceId: "",
      tenant: "state_grid",
    },
    source: "SGAPP",
    target: "32101",
    channelCode: "0902",
    channelNo: "0902",
    toPublish: "01",
    siteId: "2012000000033700",
    srvCode: "",
    serialNo: "",
    funcCode: "",
    serviceCode: {
      order: "0101154",
      uploadPic: "0101296",
      pauseSCode: "0101250",
      pauseTCode: "0101251",
      listconsumers: "0101093",
      messageList: "0101343",
      submit: "0101003",
      sbcMsg: "0101210",
      powercut: "0104514",
      BkAuth01: "f15",
      BkAuth02: "f18",
      BkAuth03: "f02",
      BkAuth04: "f17",
      BkAuth05: "f05",
      BkAuth06: "f16",
      BkAuth07: "f01",
      BkAuth08: "f03",
    },
    electricityArchives: { servicecode: "0104505", source: "0902" },
    subscriptionList: {
      srvCode: "APP_SGPMS_05_030",
      serialNo: "22",
      channelCode: "0902",
      funcCode: "22",
      target: "-1",
    },
    userInformation: { serviceCode: "01008183", source: "SGAPP" },
    userInform: { serviceCode: "0101183", source: "SGAPP" },
    elesum: {
      channelCode: "0902",
      funcCode: "WEBALIPAY_01",
      promotCode: "1",
      promotType: "1",
      serviceCode: "0101143",
      source: "app",
    },
    account: { channelCode: "0902", funcCode: "WEBA1007200" },
    doorNumberManeger: {
      source: "0902",
      target: "-1",
      channelCode: "09",
      channelNo: "09",
      serviceCode: "01010049",
      funcCode: "WEBA40050000",
      uscInfo: {
        member: "0902",
        devciceIp: "",
        devciceId: "",
        tenant: "state_grid",
      },
    },
    doorAuth: { source: "SGAPP", serviceCode: "f04" },
    xinZ: {
      serCat: "101",
      jM_busiTypeCode: "101",
      fJ_busiTypeCode: "102",
      jM_custType: "03",
      fJ_custType: "02",
      serviceType: "01",
      subBusiTypeCode: "",
      funcCode: "WEBA10070700",
      order: "0101154",
      source: "SGAPP",
      querytypeCode: "1",
    },
    onedo: {
      serviceCode: "0101046",
      source: "SGAPP",
      funcCode: "WEBA10070700",
      queryType: "03",
    },
    xinHuTongDian: {
      serCat: "110",
      busiTypeCode: "211",
      subBusiTypeCode: "21102",
      funcCode: "WEBA10071200",
      channelCode: "0902",
      source: "09",
      serviceCode: "0101183",
    },
    company: {
      serCat: "104",
      funcCode: "WEBA10070700",
      serviceType: "02",
      querytypeCode: "1",
      authFlag: "1",
      source: "SGAPP",
      order: "0101154",
    },
    charge: {
      channelCode: "09",
      funcCode: "WEBA10071300",
      channelNo: "0901",
      serCat: "102",
      jM_custType: "01",
      jM_busiTypeCode: "102",
    },
    other: {
      channelCode: "09",
      funcCode: "WEBA10079700",
      serCat: "129",
      busiTypeCode: "999",
      subBusiTypeCode: "21501",
      serviceCode: "BCP_000026",
      srvCode: "",
      serialNo: "",
    },
    vatchange: {
      submit: "0101003",
      busiTypeCode: "320",
      subBusiTypeCode: "",
      serCat: "115",
      funcCode: "WEBA10074000",
      authFlag: "1",
    },
    bill: {
      clearCache: "1",
      funcCode: "WEBALIPAY_01",
      promotType: "1",
      serviceCode: "BCP_000026",
    },
    stepelect: {
      channelCode: "0902",
      funcCode: "WEBALIPAY_01",
      promotType: "1",
      clearCache: "09",
      serviceCode: "BCP_000026",
      source: "app",
    },
    intelligentPayment: { serviceCode: "0102719", source: "SGAPP" },
    getday: {
      channelCode: "0902",
      clearCache: "11",
      funcCode: "WEBALIPAY_01",
      promotCode: "1",
      promotType: "1",
      serviceCode: "BCP_000026",
      source: "app",
    },
    mouthOut: {
      channelCode: "0902",
      clearCache: "11",
      funcCode: "WEBALIPAY_01",
      promotCode: "1",
      promotType: "1",
      serviceCode: "BCP_000026",
      source: "app",
    },
    meter: {
      serCat: "114",
      busiTypeCode: "304",
      funcCode: "WEBA10071000",
      subBusiTypeCode: "",
      serviceCode: "0101046",
      serialNo: "",
    },
    complaint: {
      busiTypeCode: "005",
      srvMode: "0902",
      anonymousFlag: "0",
      replyMode: "01",
      retvisitFlag: "01",
    },
    report: { busiTypeCode: "006" },
    tradewinds: { busiTypeCode: "019" },
    somesay: { busiTypeCode: "091" },
    faultrepair: {
      funcCode: "WEBA10070900",
      serviceCode: "0101183",
      serCat: "111",
      busiTypeCode: "001",
      subBusiTypeCode: "21505",
    },
    electronicInvoice: { serCat: "105", busiTypeCode: "0" },
    rename: {
      serviceCode: "0101046",
      funcCode: "WEBA10076100",
      busiTypeCode: "210",
      serCat: "109",
      authFlag: "1",
      gh_busiTypeCode: "211",
      gh_subusi: "21101",
      serialNo: "",
      srvCode: "",
    },
    pause: {
      subBusiTypeCode: "",
      serviceCode: "01010049",
      funcCode: "WEBA10073600",
      serCat: "107",
      busiTypeCode: "201",
      jr_busi: "201",
      serialNo: "",
      srvCode: "",
      order: "0101154",
      source: "SGAPP",
      querytypeCode: "1",
    },
    capacityRecovery: {
      serviceCode: "01010049",
      source: "SGAPP",
      srvCode: "",
      serialNo: "",
      funcCode: "WEBA10073700",
      busiTypeCode_stop: "204",
      busiTypeCode_less: "202",
      busiTypeCode: "202",
      subBusiTypeCode: "",
      serCat: "108",
      timeDay: "5",
      authFlag: "1",
    },
    electricityPriceChange: {
      serviceCode: "0101183",
      busiTypeCode: "215",
      subBusiTypeCode: "21502",
      serCat: "113",
      authFlag: "1",
      timeDay: "15",
      funcCode: "WEBA10073900WEB",
      srvCode: "",
      serialNo: "",
    },
    electricityPriceStrategyChange: {
      serviceCode: "01008183",
      busiTypeCode: "215",
      subBusiTypeCode: "21506",
      serCat: "160",
      funcCode: "WEBV00000517WEB",
      srvCode: "",
      serialNo: "",
    },
    eemandValueAdjustment: {
      serviceCode: "0101183",
      srvCode: "",
      serialNo: "",
      serCat: "112",
      funcCode: "WEBA10073800",
      busiTypeCode: "215",
      subBusiTypeCode: "21504",
      authFlag: "1",
      timeDay: "5",
      getMonthServiceCode: "0101046",
    },
    businessProgress: {
      serviceCode: "0101183",
      srvCode: "01",
      funcCode: "WEB01",
    },
    increase: {
      source: "SGAPP",
      serialNo: "",
      srvCode: "",
      serviceCode_smt: "01010049",
      serviceCode: "0101154",
      order: "0101154",
      funcCode: "WEBA10070800",
      querytypeCode: "1",
      serCat: "106",
      busiTypeCode: "111",
      subBusiTypeCode: "",
    },
    fjincrea: {
      serCat: "105",
      busiTypeCode: "110",
      subBusiTypeCode: "",
      source: "SGAPP",
      funcCode: "WEBA10070800",
      serialNo: "",
      srvCode: "",
      serviceCode_smt: "01010049",
      serviceCode: "0101154",
      order: "0101154",
      querytypeCode: "1",
    },
    persIncrea: {
      serCat: "105",
      busiTypeCode: "109",
      order: "0101154",
      subBusiTypeCode: "",
      source: "SGAPP",
      funcCode: "WEBA10070800",
      querytypeCode: "1",
    },
    fgdChange: {
      serviceCode: "0101183",
      srvCode: "01",
      channelCode: "09",
      funcCode: "WEBA10070900",
      busiTypeCode: "215",
      subBusiTypeCode: "21505",
      serCat: "111",
      authFlag: "1",
    },
    createOrder: {
      channelCode: "0902",
      funcCode: "WEBALIPAY_01",
      srvCode: "BCP_000001",
      chargeMode: "02",
      conType: "01",
      bizTypeId: "BT_ELEC",
    },
    largePopulation: {
      busiTypeCode: "383",
      funcCode: "WEBA10076800",
      subBusiTypeCode: "",
      srvCode: "",
      promotType: "",
      promotCode: "",
      channelCode: "0901",
      serCat: "383",
      serviceCode: "",
      serialNo: "",
    },
    biaoJiCode: { serviceCode: "0104507", source: "1704", channelCode: "1704" },
    biaoJiCode: { serviceCode: "0104507", source: "1704", channelCode: "1704" },
    twoGuar: {
      busiTypeCode: "402",
      subBusiTypeCode: "40201",
      funcCode: "web_twoGuar",
    },
    electTrend: { serviceCode: "BCP_00026", channelCode: "0902" },
    emergency: {
      serviceCode: "BCP_00026",
      funcCode: "A10000000",
      channelCode: "0902",
    },
    infoPublic: { serviceCode: "2545454", source: "app" },
  },
  Notify = isNode() ? require("./sendNotify") : "",
  SCRIPTNAME = "网上国网",
  NAMESPACE = "ONZ3V",
  store = new Store(NAMESPACE),
  Global =
    "undefined" != typeof globalThis
      ? globalThis
      : "undefined" != typeof window
        ? window
        : "undefined" != typeof global
          ? global
          : "undefined" != typeof self
            ? self
            : {};
Global.bizrt = jsonParse(store.get("95598_bizrt")) || {};
const log = new Logger(
    SCRIPTNAME,
    isTrue(isNode() ? process.env.WSGW_LOG_DEBUG : store.get("95598_log_debug"))
      ? "debug"
      : "info"
  ),
  USERNAME =
    (isNode() ? process.env.WSGW_USERNAME : store.get("95598_username")) || "",
  PASSWORD =
    (isNode() ? process.env.WSGW_PASSWORD : store.get("95598_password")) || "",
  SHOW_RECENT = isTrue(
    isNode()
      ? process.env.WSGW_RECENT_ELC_FEE
      : store.get("95598_recent_elc_fee")
  ),
  NOTIFY_TYPE = isNode()
    ? process.env.WSGW_NOTIFY_ALL
    : store.get("95598_notify_type");
async function getKeyCode() {
  console.log("⏳ 获取keyCode和publicKey...");
  try {
    const e = { url: `/api${$api.getKeyCode}`, method: "post", headers: {} };
    (Global.requestKey = await request(e)),
      log.info("✅ 获取keyCode和publicKey成功"),
      log.debug(`🔑 keyCode&publicKey: ${jsonStr(requestKey, null, 2)}`);
  } catch (e) {
    return Promise.reject(`获取keyCode和PublicKey失败: ${e}`);
  } finally {
    console.log("🔚 获取keyCode和publicKey结束");
  }
}
async function getVerifyCode() {
  console.log("⏳ 获取验证码...");
  try {
    const e = {
        url: `/api${$api.loginVerifyCodeNew}`,
        method: "post",
        data: {
          password: PASSWORD,
          account: USERNAME,
          canvasHeight: 200,
          canvasWidth: 310,
        },
        headers: { ...requestKey },
      },
      o = await request(e);
    log.info("✅ 获取验证码凭证成功"), log.debug(`🔑 验证码凭证: ${o.ticket}`);
    const { data: r } = await Recoginze(o.canvasSrc);
    return (
      log.info("✅ 识别验证码成功"),
      log.debug(`🔑 验证码: ${r}`),
      { code: r, ticket: o.ticket }
    );
  } catch (e) {
    return Promise.reject("获取验证码失败: " + e);
  } finally {
    console.log("🔚 获取验证码结束");
  }
}
async function login(e, o) {
  console.log("⏳ 登录中...");
  try {
    const r = {
        url: `/api${$api.loginTestCodeNew}`,
        method: "post",
        headers: { ...requestKey },
        data: {
          loginKey: e,
          code: o,
          params: {
            uscInfo: {
              devciceIp: "",
              tenant: "state_grid",
              member: "0902",
              devciceId: "",
            },
            quInfo: {
              optSys: "android",
              pushId: "000000",
              addressProvince: "110100",
              password: PASSWORD,
              addressRegion: "110101",
              account: USERNAME,
              addressCity: "330100",
            },
          },
          Channels: "web",
        },
      },
      { bizrt: s } = await request(r);
    if (!(s?.userInfo?.length > 0))
      return Promise.reject("登录失败: 请检查信息填写是否正确! ");
    store.set("95598_bizrt", jsonStr(s)),
      (Global.bizrt = s),
      log.info("✅ 登录成功"),
      log.debug(
        `🔑 用户凭证: ${s.token}`,
        `👤 用户信息: ${s.userInfo[0].nickname || s.userInfo[0].loginAccount}`
      );
  } catch (e) {
    return /验证错误/.test(e)
      ? (log.error(`滑块验证出错, 重新登录: ${e}`), await doLogin())
      : Promise.reject(`登陆失败: ${e}`);
  } finally {
    console.log("🔚 登录结束");
  }
}
async function getAuthcode() {
  console.log("⏳ 获取授权码...");
  try {
    const e = {
        url: `/api${$api.getAuth}`,
        method: "post",
        headers: { ...requestKey, token: bizrt.token },
      },
      { redirect_url: o } = await request(e);
    (Global.authorizecode = o.split("?code=")[1]),
      log.info("✅ 获取授权码成功"),
      log.debug(`🔑 授权码: ${authorizecode}`);
  } catch (e) {
    return Promise.reject(`获取授权码失败: ${e}`);
  } finally {
    console.log("🔚 获取授权码结束");
  }
}
async function getAccessToken() {
  console.log("⏳ 获取凭证...");
  try {
    const e = {
      url: `/api${$api.getWebToken}`,
      method: "post",
      headers: {
        ...requestKey,
        token: bizrt.token,
        authorizecode: authorizecode,
      },
    };
    (Global.accessToken = await request(e).then((e) => e.access_token)),
      log.info("✅ 获取凭证成功"),
      log.debug(`🔑 AccessToken: ${accessToken}`);
  } catch (e) {
    return Promise.reject(`获取凭证失败: ${e}`);
  } finally {
    console.log("🔚 获取凭证结束");
  }
}
async function getBindInfo() {
  console.log("⏳ 查询绑定信息...");
  try {
    const e = {
      url: `/api${$api.searchUser}`,
      method: "post",
      headers: { ...requestKey, token: bizrt.token, acctoken: accessToken },
      data: {
        serviceCode: $configuration.userInform.serviceCode,
        source: $configuration.source,
        target: $configuration.target,
        uscInfo: {
          member: $configuration.uscInfo.member,
          devciceIp: $configuration.uscInfo.devciceIp,
          devciceId: $configuration.uscInfo.devciceId,
          tenant: $configuration.uscInfo.tenant,
        },
        quInfo: { userId: bizrt.userInfo[0].userId },
        token: bizrt.token,
        Channels: "web",
      },
    };
    (Global.bindInfo = await request(e).then((e) => e.bizrt)),
      log.info("✅ 获取绑定信息成功"),
      log.debug(`🔑 用户绑定信息: ${jsonStr(bindInfo, null, 2)}`);
  } catch (e) {
    return Promise.reject(`获取绑定信息失败: ${e}`);
  } finally {
    console.log("🔚 查询绑定信息结束");
  }
}
async function getElcFee(e) {
  console.log("⏳ 查询电费...");
  try {
    const o = bindInfo.powerUserList[e],
      [r] = bizrt.userInfo,
      s = {
        url: `/api${$api.accapi}`,
        method: "post",
        headers: { ...requestKey, token: bizrt.token, acctoken: accessToken },
        data: {
          data: {
            srvCode: "",
            serialNo: "",
            channelCode: $configuration.account.channelCode,
            funcCode: $configuration.account.funcCode,
            acctId: r.userId,
            userName: r.loginAccount ? r.loginAccount : r.nickname,
            promotType: "1",
            promotCode: "1",
            userAccountId: r.userId,
            list: [
              {
                consNoSrc: o.consNo_dst,
                proCode: o.proNo,
                sceneType: o.constType,
                consNo: o.consNo,
                orgNo: o.orgNo,
              },
            ],
          },
          serviceCode: "0101143",
          source: $configuration.source,
          target: o.proNo || o.provinceId,
        },
      };
    (Global.eleBill = await request(s).then((e) => e.list[0])),
      log.info("✅ 查询电费成功"),
      log.debug(`🔑 电费信息: ${jsonStr(Global.eleBill, null, 2)}`);
  } catch (e) {
    return Promise.reject(`查询电费失败: ${e}`);
  } finally {
    console.log("🔚 查询电费结束");
  }
}
async function getDayElecQuantity(e) {
  console.log("⏳ 获取日用电量...");
  try {
    const o = bindInfo.powerUserList[e],
      [r] = bizrt.userInfo,
      s = getBeforeDate(8),
      n = getBeforeDate(1),
      t = {
        url: `/api${$api.busInfoApi}`,
        method: "post",
        headers: { ...requestKey, token: bizrt.token, acctoken: accessToken },
        data: {
          params1: {
            serviceCode: $configuration.serviceCode,
            source: $configuration.source,
            target: $configuration.target,
            uscInfo: {
              member: $configuration.uscInfo.member,
              devciceIp: $configuration.uscInfo.devciceIp,
              devciceId: $configuration.uscInfo.devciceId,
              tenant: $configuration.uscInfo.tenant,
            },
            quInfo: { userId: r.userId },
            token: bizrt.token,
          },
          params3: {
            data: {
              acctId: r.userId,
              consNo: o.consNo_dst,
              consType: "02" == o.constType ? "02" : "01",
              endTime: n,
              orgNo: o.orgNo,
              queryYear: new Date().getFullYear().toString(),
              proCode: o.proNo || o.provinceId,
              serialNo: "",
              srvCode: "",
              startTime: s,
              userName: r.nickname ? r.nickname : r.loginAccount,
              funcCode: $configuration.getday.funcCode,
              channelCode: $configuration.getday.channelCode,
              clearCache: $configuration.getday.clearCache,
              promotCode: $configuration.getday.promotCode,
              promotType: $configuration.getday.promotType,
            },
            serviceCode: $configuration.getday.serviceCode,
            source: $configuration.getday.source,
            target: o.proNo || o.provinceId,
          },
          params4: "010103",
        },
      },
      c = await request(t);
    log.info("✅ 获取日用电量成功"),
      log.debug(jsonStr(c, null, 2)),
      (Global.dayElecQuantity = c);
  } catch (e) {
    return Promise.reject("获取日用电量失败: " + e);
  } finally {
    console.log("🔚 获取日用电量结束");
  }
}
async function getMonthElecQuantity(e) {
  console.log("⏳ 获取月用电量...");
  const o = bindInfo.powerUserList[e],
    [r] = bizrt.userInfo;
  try {
    let queryYear = new Date().getFullYear().toString();
    // let queryYear = '2024';
    let e = {
      url: `/api${$api.busInfoApi}`,
      method: "post",
      headers: { ...requestKey, token: bizrt.token, acctoken: accessToken },
      data: {
        params1: {
          serviceCode: $configuration.serviceCode,
          source: $configuration.source,
          target: $configuration.target,
          uscInfo: {
            member: $configuration.uscInfo.member,
            devciceIp: $configuration.uscInfo.devciceIp,
            devciceId: $configuration.uscInfo.devciceId,
            tenant: $configuration.uscInfo.tenant,
          },
          quInfo: { userId: r.userId },
          token: bizrt.token,
        },
        params3: {
          data: {
            acctId: r.userId,
            consNo: o.consNo_dst,
            consType: "02" == o.constType ? "02" : "01",
            orgNo: o.orgNo,
            proCode: o.proNo || o.provinceId,
            provinceCode: o.proNo || o.provinceId,
            queryYear: queryYear,
            serialNo: "",
            srvCode: "",
            userName: r.nickname ? r.nickname : r.loginAccount,
            funcCode: $configuration.mouthOut.funcCode,
            channelCode: $configuration.mouthOut.channelCode,
            clearCache: $configuration.mouthOut.clearCache,
            promotCode: $configuration.mouthOut.promotCode,
            promotType: $configuration.mouthOut.promotType,
          },
          serviceCode: $configuration.mouthOut.serviceCode,
          source: $configuration.mouthOut.source,
          target: o.proNo || o.provinceId,
        },
        params4: "010102",
      },
    };
    const s = await request(e);
    if (!s.mothEleList || s.mothEleList.length < 12) {
      queryYear = (new Date().getFullYear() - 1).toString();
      e.data.params3.data.queryYear = queryYear;
      const prevYearData = await request(e);
      let arr = s.mothEleList || [];
      s.mothEleList = prevYearData.mothEleList.concat(arr);
    }
    log.info("✅ 获取月用电量成功"),
      log.debug(jsonStr(s, null, 2)),
      (Global.monthElecQuantity = s);
  } catch (e) {
    return Promise.reject(`获取月用电量失败: ${e}`);
  } finally {
    console.log("🔚 获取月用电量结束");
  }
}
async function doLogin() {
  const { code: e, ticket: o } = await getVerifyCode();
  await login(o, e);
}
async function showNotice() {
  // console.log(''),
  //   console.log('1. 本脚本仅用于学习研究，禁止用于商业用途'),
  //   console.log('2. 本脚本不保证准确性、可靠性、完整性和及时性'),
  //   console.log('3. 任何个人或组织均可无需经过通知而自由使用'),
  //   console.log('4. 作者对任何脚本问题概不负责，包括由此产生的任何损失'),
  //   console.log(
  //     '5. 如果任何单位或个人认为该脚本可能涉嫌侵犯其权利，应及时通知并提供身份证明、所有权证明，我将在收到认证文件确认后删除'
  //   ),
  //   console.log('6. 请勿将本脚本用于商业用途，由此引起的问题与作者无关'),
  //   console.log('7. 本脚本及其更新版权归作者所有'),
  console.log("");
}
function formatDate(dateStr) {
  // 分割日期字符串
  var year = dateStr.substring(0, 4);
  var month = dateStr.substring(4, 6);
  var day = dateStr.substring(6, 8);

  // 返回格式化的日期字符串
  return year + "-" + month + (day ? "-" + day : "");
}
// 修改发送mqtt消息至homeassistant
async function sendMsg(e, eleBill, dayList, monthElecQuantity) {
  const host =
      (isNode() ? process.env.WSGW_mqtt_host : store.get("95598_mqtt_host")) ||
      "",
    port =
      (isNode() ? process.env.WSGW_mqtt_port : store.get("95598_mqtt_port")) ||
      "",
    mqtt_username =
      (isNode()
        ? process.env.WSGW_mqtt_username
        : store.get("95598_mqtt_username")) || "",
    mqtt_password =
      (isNode()
        ? process.env.WSGW_mqtt_password
        : store.get("95598_mqtt_password")) || "";

  const mqtt = require("mqtt");
  const clientId = "mqtt_qldocker";

  const connectUrl = `mqtt://${host}:${port}`;
  const client = mqtt.connect(connectUrl, {
    clientId,
    clean: true,
    connectTimeout: 2000,
    username: mqtt_username,
    password: mqtt_password,
    reconnectPeriod: 1000,
  });

  const topic = "nodejs/state-grid";
  let data = eleBill;
  dayList = dayList
    .filter((val) => {
      return val.dayElePq != "-";
    })
    .map((val) => {
      val.day = formatDate(val.day);
      return val;
    });
  let monthList = [];
  if (monthElecQuantity.mothEleList) {
    monthList = monthElecQuantity.mothEleList.map((val) => {
      val.month = formatDate(val.month);
      return val;
    });
  }

  data.dayList = dayList;
  data.monthList = monthList;
  data.totalEleNum = monthElecQuantity?.dataInfo?.totalEleNum || 0;
  data.totalEleCost = monthElecQuantity?.dataInfo?.totalEleCost || 0;
  client.on("connect", () => {
    console.log("mqtt:Connected");
    //   console.log(data)
    client.publish(
      topic,
      JSON.stringify(data),
      { qos: 0, retain: false },
      (error) => {
        if (error) {
          console.error(error);
        } else {
          console.log("mqtt:Published");
        }
      }
    );
  });

  setTimeout(() => {
    client.end();
  }, 2000);

  await new Promise((resolve, reject) => {
    setTimeout(() => resolve("done!"), 2000);
  });
}
// async function sendMsg(e, o, r, s) {
//   const n = s?.['open-url'] || s?.openUrl || s?.$open || s?.url,
//     t = s?.['media-url'] || s?.mediaUrl || s?.$media;
//   isNode()
//     ? ((r += n ? `\n点击跳转: ${n}` : ''),
//       (r += t ? `\n多媒体: ${t}` : ''),
//       console.log(`${e}\n${o}\n${r}\n`),
//       await Notify.sendNotify(`${e}\n${o}`, r))
//     : notify(e, o, r, s);
// }
(async () => {
  if ((await showNotice(), !USERNAME || !PASSWORD))
    return sendMsg(SCRIPTNAME, "请先配置网上国网账号密码!");
  await getKeyCode(),
    (bizrt?.token && bizrt?.userInfo) || (await doLogin()),
    await getAuthcode(),
    await getAccessToken(),
    await getBindInfo(),
    isTrue(NOTIFY_TYPE) ||
      ((bindInfo.powerUserList = bindInfo.powerUserList.filter(
        (e) => "1" === e.isDefault
      )),
      bindInfo.powerUserList.length > 1 &&
        (bindInfo.powerUserList = bindInfo.powerUserList.filter(
          (e) => "01" === e.elecTypeCode
        )));
  for (let e = 0; e < bindInfo.powerUserList.length; e++) {
    await getElcFee(e),
      await getDayElecQuantity(e),
      await getMonthElecQuantity(e);
    const o = bindInfo.powerUserList[e],
      { dataInfo: r } = monthElecQuantity,
      { sevenEleList: s, totalPq: n } = dayElecQuantity,
      t =
        Number(eleBill?.historyOwe || "0") > 0 ||
        Number(eleBill?.sumMoney || "0") < 0;
    let c = Math.abs(eleBill?.sumMoney || "0");
    c = t ? `-${c}` : c;
    let a = "";
    eleBill.totalPq && (a += `本期电量: ${eleBill.totalPq}度`),
      eleBill.sumMoney && (a += `  账户余额: ${c}元`),
      (a += `\n截至日期: ${eleBill.date}`),
      r &&
        r.totalEleNum &&
        r.totalEleCost &&
        (a += `\n年度用电: ${r.totalEleNum}度  累计花费: ${r.totalEleCost}元`),
      isTrue(SHOW_RECENT) ||
        (eleBill.dayNum
          ? (a += `\n预计可用: ${eleBill.dayNum}天`)
          : eleBill.prepayBal && (a += `\n预存电费: ${eleBill.prepayBal}元`)),
      o.consNo_dst &&
        (a += `\n户号信息: ${o.consNo_dst}${
          o.consName_dst ? `|${o.consName_dst}` : ""
        }`),
      o.orgName && (a += `\n供电单位: ${o.orgName}`),
      o.elecAddr_dst && (a += `\n用电地址: ${o.elecAddr_dst}`),
      n && (a += `\n五日用电: ${n}度`),
      isTrue(SHOW_RECENT) &&
        s.forEach((e, o) => {
          Number(e.dayElePq) && (a += `\n${e.day}用电: ${e.dayElePq}度⚡`);
        }),
      // console.log(monthElecQuantity)
      // await sendMsg(SCRIPTNAME, '', a);
      await sendMsg(SCRIPTNAME, eleBill, s, monthElecQuantity);
  }
})()
  .catch((e) => {
    /无效|失效|过期|重新获取|请求异常/.test(e) &&
      (store.clear("95598_bizrt"), console.log("✅ 清理缓存数据成功")),
      log.error(e);
  })
  .finally(done);
