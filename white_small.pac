var wall_proxy = "SOCKS5 127.0.0.1:1080; SOCKS 127.0.0.1:1080;";
var nowall_proxy = "DIRECT;";
var direct = "DIRECT;";
var ip_proxy = "DIRECT;";

/*
 * Copyright (C) 2014 breakwa11
 * https://github.com/breakwa11/gfw_whitelist
 */

var white_domains = {"am":{
"126":1,
"51":1
},"biz":{
"7daysinn":1,
"baozhuang":1,
"bengfa":1,
"tongye":1,
"yuanyi":1,
"zhaoming":1
},"cc":{
"0316":1,
"bamaol":1,
"bczx":1,
"bendiw":1,
"bjjf":1,
},"cm":{
"4":1,
"60":1,
"bearing":1,
"hebei":1,
"yinshua":1
},"co":{
"425300":1,
"banzhu":1,
"hongfeng":1,
"huas":1,
"lixin":1,
"xiaomayi":1,
"xiapu":1,
"ychdzx":1
},"com":{
"0-6":1,
"0001688":1,
"001cndc":1,
"5jzp":1,
"cehome":1,
"cehui8":1,
},"tw":{
"hexun.com":1,
"taiwandao":1
},"us":{
"pangu":1
},"ws":{
"0798":1
},"xn--fiqs8s":{
"":1
}
};

var subnetIpRangeList = [
0,1,
167772160,184549376,	//10.0.0.0/8
2886729728,2887778304,	//172.16.0.0/12
3232235520,3232301056,	//192.168.0.0/16
2130706432,2130706688	//127.0.0.0/24
];

var hasOwnProperty = Object.hasOwnProperty;

function check_ipv4(host) {
	// check if the ipv4 format (TODO: ipv6)
	//   http://home.deds.nl/~aeron/regex/
	var re_ipv4 = /^\d+\.\d+\.\d+\.\d+$/g;
	if (re_ipv4.test(host)) {
		// in theory, we can add chnroutes test here.
		// but that is probably too much an overkill.
		return true;
	}
}
function convertAddress(ipchars) {
	var bytes = ipchars.split('.');
	var result = (bytes[0] << 24) |
	(bytes[1] << 16) |
	(bytes[2] << 8) |
	(bytes[3]);
	return result >>> 0;
}
function isInSubnetRange(ipRange, intIp) {
	for ( var i = 0; i < 10; i += 2 ) {
		if ( ipRange[i] <= intIp && intIp < ipRange[i+1] )
			return true;
	}
}
function getProxyFromDirectIP(strIp) {
	var intIp = convertAddress(strIp);
	if ( isInSubnetRange(subnetIpRangeList, intIp) ) {
		return direct;
	}
	return ip_proxy;
}
function isInDomains(domain_dict, host) {
	var suffix;
	var pos1 = host.lastIndexOf('.');

	suffix = host.substring(pos1 + 1);
	if (suffix == "cn") {
		return true;
	}

	var domains = domain_dict[suffix];
	if ( domains === undefined ) {
		return false;
	}
	host = host.substring(0, pos1);
	var pos = host.lastIndexOf('.');

	while(1) {
		if (pos <= 0) {
			if (hasOwnProperty.call(domains, host)) {
				return true;
			} else {
				return false;
			}
		}
		suffix = host.substring(pos + 1);
		if (hasOwnProperty.call(domains, suffix)) {
			return true;
		}
		pos = host.lastIndexOf('.', pos - 1);
	}
}
function FindProxyForURL(url, host) {
	url=""+url;
	host=""+host;
	if ( isPlainHostName(host) === true ) {
		return direct;
	}
	if ( check_ipv4(host) === true ) {
		return getProxyFromDirectIP(host);
	}
	if ( isInDomains(white_domains, host) === true ) {
		return nowall_proxy;
	}
	return wall_proxy;
}

