


local twenty_one_poker_config = {
	[1]  	= "image/poker/card_spades_a.png",
	[2]  	= "image/poker/card_spades_2.png",
	[3]  	= "image/poker/card_spades_3.png",
	[4] 	= "image/poker/card_spades_4.png",
	[5]  	= "image/poker/card_spades_5.png",
	[6]  	= "image/poker/card_spades_6.png",
	[7]  	= "image/poker/card_spades_7.png",
	[8]  	= "image/poker/card_spades_8.png",
	[9]  	= "image/poker/card_spades_9.png",
	[10]  	= "image/poker/card_spades_10.png",
	[11]  	= "image/poker/card_spades_j.png",
	[12]    = "image/poker/card_spades_q.png",
	[13]    = "image/poker/card_spades_k.png",

	[14]     = "image/poker/fangkuaia.png",
	[15]     = "image/poker/fangkuai2.png",
	[16]     = "image/poker/fangkuai3.png",
	[17]     = "image/poker/fangkuai4.png",
	[18]     = "image/poker/fangkuai5.png",
	[19]     = "image/poker/fangkuai6.png",
	[20]     = "image/poker/fangkuai7.png",
	[21]     = "image/poker/fangkuai8.png",
	[22]     = "image/poker/fangkuai9.png",
	[23]     = "image/poker/fangkuai10.png",
	[24]     = "image/poker/fangkuaij.png",
	[25]     = "image/poker/fangkuaiq.png",
	[26]     = "image/poker/fangkuaik.png",

	[27]     = "image/poker/heitao2.png",
	[28]     = "image/poker/heitao3.png",
	[29]     = "image/poker/heitao4.png",
	[30]     = "image/poker/heitao5.png",
	[31]     = "image/poker/heitao6.png",
	[32]     = "image/poker/heitao7.png",
	[33]     = "image/poker/heitao8.png",
	[34]     = "image/poker/heitao9.png",
	[35]     = "image/poker/heitao10.png",
	[36]     = "image/poker/heitaoj.png",
	[37]     = "image/poker/heitaok.png",
	[38]     = "image/poker/heitaoq.png",
	[39]     = "image/poker/heitaoa.png",

	[40]     = "image/poker/hongxin2.png",
	[41]     = "image/poker/hongxin3.png",
	[42]     = "image/poker/hongxin4.png",
	[43]     = "image/poker/hongxin5.png",
	[44]     = "image/poker/hongxin6.png",
	[45]     = "image/poker/hongxin7.png",
	[46]     = "image/poker/hongxin8.png",
	[47]     = "image/poker/hongxin9.png",
	[48]     = "image/poker/hongxin10.png",
	[49]     = "image/poker/hongxina.png",
	[50]     = "image/poker/card_hearts_j.png",
	[51]     = "image/poker/card_hearts_k.png",
	[52]     = "image/poker/card_hearts_q.png",
}

local twenty_one_num_config = {
	[1]		 = { 1,11 },
	[2]		 = { 2 },
	[3]		 = { 3 },
	[4]		 = { 4 },
	[5]		 = { 5 },
	[6]		 = { 6 },
	[7]		 = { 7 },
	[8]		 = { 8 },
	[9]		 = { 9 },
	[10]     = { 10 },
	[11]     = { 10 },
	[12]     = { 10 },
	[13]     = { 10 },

	[14]     = { 1,11 },
	[15]     = { 2 },
	[16]     = { 3 },
	[17]     = { 4 },
	[18]     = { 5 },
	[19]     = { 6 },
	[20]     = { 7 },
	[21]     = { 8 },
	[22]     = { 9 },
	[23]     = { 10 },
	[24]     = { 10 },
	[25]     = { 10 },
	[26]     = { 10 },

	[27]     = { 2 },
	[28]     = { 3 },
	[29]     = { 4 },
	[30]     = { 5 },
	[31]     = { 6 },
	[32]     = { 7 },
	[33]     = { 8 },
	[34]     = { 9 },
	[35]     = { 10 },
	[36]     = { 10 },
	[37]     = { 10 },
	[38]     = { 10 },
	[39]     = { 1,11 },

	[40]     = { 2 },
	[41]     = { 3 },
	[42]     = { 4 },
	[43]     = { 5 },
	[44]     = { 6 },
	[45]     = { 7 },
	[46]     = { 8 },
	[47]     = { 9 },
	[48]     = { 10 },
	[49]     = { 1,11 },
	[50]     = { 10 },
	[51]     = { 10 },
	[52]     = { 10 },
}


local twenty_one_version = 2 --有 1:中文版本 2:英文版本

rawset(_G,"twenty_one_poker_config",twenty_one_poker_config)
rawset(_G,"twenty_one_num_config",twenty_one_num_config)
rawset(_G,"twenty_one_version",twenty_one_version)