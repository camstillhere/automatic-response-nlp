require 'benchmark'
require 'date'
require 'java'
require 'json'
require 'net/http'
require 'pathname'
require 'securerandom'
require 'time'
require 'uri'
require 'set'
start = Time.now
$timesToFinish={}

def startClock(type)
	$timesToFinish[type]={
		"s"=>Time.now()
	}
end

def endClock(type)
	$timesToFinish[type]['e']=Time.now()
	$timesToFinish[type]['d']=($timesToFinish[type]['e'] - $timesToFinish[type]['s'])
	$timesToFinish[type]['p']=humanize($timesToFinish[type]['d'])
end

def humanize(secs)
	remainingMilliseconds=secs*1000
	
	formatters={
		"Milliseconds"=>1,
		"Seconds"=>1000,
		"Minutes"=>60* 1000,
		"Hours"=>60*60*1000,
		"Days"=>24*60*60*1000
	}
	phrase=[]
	formatters.sort_by{|key,value|-value}.each do | key,value |
		if(remainingMilliseconds >= value)
			figure=(remainingMilliseconds - (remainingMilliseconds % value)) / value
			if(key=='Millisecond')
				figure=figure.round(0)
			end
			phrase.push("#{figure.round(0)} #{key}")
			remainingMilliseconds=remainingMilliseconds - (figure * value)
		end
		
	end
	return phrase.join(", ")
	
end


$logger=Java::OrgApacheLog4j::Logger.getRootLogger()

$nlpClient=nil

class NLP
	def initialize(baseUrl,username,password)
		@https=nil
		@headers={
			"Content-Type"=>"application/json"
		}
		@baseUrl=baseUrl
		@accessToken=login(username,password)
		@headers["Authorization"]="Bearer #{@accessToken}"
	end

	def login(username,password)
		query="""mutation GQL_LOGIN($username: String!, $password: String!) {
		  login(input: {username: $username, password: $password}) {
		    access_token
		    expires_in
		    refresh_token
		    __typename
		  }
		}"""
		variables={
			"username"=> username,
			"password"=>password
		}
		result=postGraphQL('GQL_LOGIN',query,variables)
		return result['login']['access_token']
	end

	def processText(text,language="F760F66066650AB540C48A08194823CABD7C27DE1160FBA235147F362998B39ACDCCB7AE21B08B7245640F0639E8436ADD1C477E31001B4255B49FD64938D33A")
		query="""mutation GQL_PROCESS_TEXT($input: ProcessTextInput!, $options: ProcessTextOptionsInput) {
		  processText(input: $input, options: $options) {
		    id
		    error {
		      message
		      __typename
		    }
		    status
		    __typename
		  }
		}"""
		variables={
			"input": {
				"text"=> text
			},
			"options"=> {
				"languageId"=>language
			}
		}
		result=postGraphQL('GQL_PROCESS_TEXT',query,variables)
		return result['processText']['id']
	end

	def getSearchResult(id)
		query="""fragment FRAGMENT_PROXIMITY on Proximity {
		  addends
		  value
		  __typename
		}
		
		fragment FRAGMENT_LEXEME_POSITION on TextProcessingLexemePosition {
		  length
		  offset
		  __typename
		}
		
		fragment FRAGMENT_TEXT_PROCESSING_RESULT on TextProcessingResult {
		  rawJSON
		  entities {
		    topic {
		      entity {
		        __typename
		        ... on TopicEntity {
		          id
		          mainName {
		            id
		            name
		            __typename
		          }
		          topic {
		            id
		            name
		            __typename
		          }
		          topicType {
		            id
		            name
		            __typename
		          }
		          __typename
		        }
		      }
		      lexemePositions {
		        ...FRAGMENT_LEXEME_POSITION
		        __typename
		      }
		      relevance
		      __typename
		    }
		    geo {
		      entity {
		        __typename
		        ... on GeoEntity {
		          id
		          mainName {
		            id
		            name
		            __typename
		          }
		          country {
		            id
		            name
		            __typename
		          }
		          parent {
		            id
		            mainName {
		              id
		              name
		              __typename
		            }
		            __typename
		          }
		          __typename
		        }
		      }
		      lexemePositions {
		        ...FRAGMENT_LEXEME_POSITION
		        __typename
		      }
		      relevance
		      __typename
		    }
		    __typename
		  }
		  idfScores {
		    pos
		    score
		    word
		    lexemePosition {
		      ...FRAGMENT_LEXEME_POSITION
		      __typename
		    }
		    __typename
		  }
		  idfRequirementScore
		  niceToHavesScore
		  sentimentIndex
		  tenseIndexes {
		    past
		    present
		    future
		    __typename
		  }
		  timeIndex
		  proximities {
		    topic {
		      proximity {
		        ...FRAGMENT_PROXIMITY
		        __typename
		      }
		      topic {
		        name
		        id
		        __typename
		      }
		      topicTypeProximities {
		        proximity {
		          ...FRAGMENT_PROXIMITY
		          __typename
		        }
		        topicType {
		          name
		          id
		          __typename
		        }
		        __typename
		      }
		      __typename
		    }
		    skillset {
		      skillset {
		        name
		        id
		        __typename
		      }
		      skillProximities {
		        skill {
		          name
		          id
		          __typename
		        }
		        proximity {
		          ...FRAGMENT_PROXIMITY
		          __typename
		        }
		        __typename
		      }
		      __typename
		    }
		    __typename
		  }
		  stopWords {
		    length
		    offset
		    __typename
		  }
		  wordSummary {
		    geoLocationsCount
		    stopWordsCount
		    topicsCount
		    uncategorizedWordsCount
		    uniqueGeoEntitiesCount
		    uniqueTopicsEntitiesCount
		    wordsCount
		    __typename
		  }
		  annotationSet
		  profileResults
		  skillKeywords
		  __typename
		}
		
		query GQL_SEARCH_TASK($id: ID!) {
		  searchTask(id: $id) {
		    error {
		      message
		      __typename
		    }
		    type {
		      id
		      name
		      description
		      __typename
		    }
		    id
		    status
		    parameters
		    result {
		      ...FRAGMENT_TEXT_PROCESSING_RESULT
		      __typename
		    }
		    timestamps {
		      createdAt
		      startedAt
		      endedAt
		      __typename
		    }
		    __typename
		  }
		}
		"""
		variables={
			"id"=>id
		}
		result=postGraphQL('GQL_SEARCH_TASK',query,variables)
		if(result['searchTask']['status']!="RUNNING")
			return result['searchTask']['result']['rawJSON']
		else
			return getSearchResult(id)
		end
	end
	
	def postGraphQL(operation,query,variables)
		uri = URI.parse(@baseUrl)
		if(@https.nil?)
			@https = Net::HTTP.new(uri.host, uri.port)
			@https.verify_mode = OpenSSL::SSL::VERIFY_NONE
			@https.use_ssl=true
			@https.start
		end
		begin
		
			request = Net::HTTP::Post.new(uri.request_uri, @headers)
			request.body = {
				"operationName"=> operation,
				"variables"=>variables ,
				"query": query
			}.to_json
			response = @https.request(request)
			$logger.trace("Call to #{@baseUrl} returned #{response.code}.\n#{response.body}")
			if response.body != nil
				begin
					return JSON.parse(response.body)['data']
				rescue
					$logger.warn("Unable to parse response from translation service or it's blank\n#{response.body}")
				end
			end
		rescue => ex
			$logger.warn(ex.message)
			$logger.warn(ex.backtrace.to_s)
		end
	end
	
end


$config=JSON.parse(File.read('C:/OOO/config.json'))

startClock("Loading engine")
require 'json'
mySourceItemFactory=utilities.createSourceItemFactory()
endClock("Loading engine")
physicalEvidencePath=ARGV[0]
#puts("Navigating for Items")
if(ARGV[0].nil?)
	physicalEvidencePath='C:/OOO/outlookIn/0000000058FC3E46A83F30499D4E14DAAE0BDFB30700C9C8BCB19AC95A4682DFAB5595E4916000000000010C0000C9C8BCB19AC95A4682DFAB5595E49160000341A644390000.msg'
end

startClock("Processing email and attachments")
$physicalEvidenceName=File.basename(physicalEvidencePath, File.extname(physicalEvidencePath))
mySourceItem=mySourceItemFactory.openFile(physicalEvidencePath)

$results=[]

def getTLI(mySourceItem)
	if(mySourceItem.isTopLevel())
		return mySourceItem
	else
		return getTLI(mySourceItem.getChildren().first())
	end
end

def cleanText(text)
	return text.to_s.strip()
	.gsub(/^\./,"")
	.gsub(/[\r\n]+/,". ")
	.gsub(/[\s\t\u00A0 ]+/," ")
	.strip()
	.gsub(" .",".")
	.gsub(",.",", ")
	.squeeze('.')
	.squeeze(' ')
	.gsub(/\u0000-\u0020/,' ')
	.gsub("\342\200\231", "'")
	.gsub("\342\200\176","'")
	.gsub("\342\200\177","'")
	.gsub("\342\200\230","'")
	.gsub("\342\200\231","'")
	.gsub("\342\200\232",',')
	.gsub("\342\200\233","'")
	.gsub("\342\200\234",'"')
	.gsub("\342\200\235",'"')
	.gsub("\342\200\041",'-')
	.gsub("\342\200\174",'-')
	.gsub("\342\200\220",'-')
	.gsub("\342\200\223",'-')
	.gsub("\342\200\224",'--')
	.gsub("\342\200\225",'--')
	.gsub("\342\200\042",'--')
	.gsub("\342\200\246",'...')
	.gsub(/\P{ASCII}/,' ') #anything else? ditch it.
	.gsub("---------- Forwarded message ---------"," ")
	.gsub("View Web Version"," ")
	.gsub(" .",".")
	.gsub(/-+\./,".")
	.gsub(":.",":")
	.gsub("!.","!")
	.squeeze('.')
	.squeeze(' ')
	.strip()
end

def recursiveChildren(child)
	attachments=[]
	attachment={}
	attachment['name']=child.getName()[0, 10000]
	attachment['kind']=child.getKind().getName()
	attachment['text']=cleanText(child.getText().toString())[0, 10000]
	attachment['tli']=false
	if(!(attachment['text'].empty?))
		attachments.push(attachment)
	else
		child.getChildren().each do | descendant |
			recursiveChildren(descendant).each do | baby |
				attachments.push(baby)
			end
		end
	end
	return attachments
end

def getAttachments(tli)
	comms=tli.getCommunication()
	item={}
	item['name']=tli.getName()[0, 10000]
	item['text']=cleanText(tli.getText().toString())[0, 10000]
	firstFrom=tli.getCommunication().getFrom().first()
	item['from']=firstFrom.getPersonal().split(' ').first()
	item['date']=comms.getDateTime()
	$timesToFinish['Time since you sent']={
		"d"=>org.joda.time.Duration.new(item['date'],org.joda.time.DateTime.now).getStandardSeconds(),
		"p"=>humanize(org.joda.time.Duration.new(item['date'],org.joda.time.DateTime.now).getStandardSeconds()) 
	}
	
	item['tli']=true
	
	item['internal']=false
	block="From: " + comms.getFrom().map{|f|f.toDisplayString()}.join(";")
	block=block + "\n<br>Sent: " + comms.getDateTime().toString()
	if(comms.getCc().size() > 0)
		block=block + "\n<br>Cc: " + comms.getCc().map{|f|f.toDisplayString()}.join(";")
	end
	if(comms.getBcc().size() > 0)
		block=block + "\n<br>Bcc: " + comms.getBcc().map{|f|f.toDisplayString()}.join(";")
	end
	block=block + "\n<br>To: " + comms.getTo().map{|f|f.toDisplayString()}.join(";")
	block=block + "\n<br>Subject: " + tli.getName()
	item['replyBlock']=block
	if($config['permittedDomains'].include? firstFrom.getAddress().gsub(/"/,"").split('@').last())
		item['internal']=true
	end
	if($config['permittedAddress'].include? firstFrom.getAddress().gsub(/"/,""))
		item['internal']=true
	end
	$results.push(item)
	
	tli.getChildren().each do | child |
		recursiveChildren(child).each do | attachment |
			$results.push(attachment)
		end
		child.close()
	end
	tli.close()
end
tli=getTLI(mySourceItem)
selfSending=false
if(tli.getCommunication().getFrom().first().getAddress().include? 'cameron.stiller@nuix.com')
	selfSending=true
	
else
	getAttachments(tli)
end

begin
	tli.close()
rescue => ex
	#just in case
end

mySourceItemFactory.close()
endClock("Processing email and attachments")

if(selfSending)
	$logger.info("I don't want to make a loop... bail!")
	if(!(ARGV[0].nil?))
		File.delete(physicalEvidencePath)
	end
	exit
end

offsetTypes={
	"topicEntities"=>{
		"colour"=>"#66BB6A",
		"name"=>"Lexeme: Phrases relating to a topic",
		"underline"=>true
	},
	"geoEntities"=>{
		"colour"=>"#42a4f5",
		"name"=>"Geographical Location: Places, locations, landmarks",
		"underline"=>true
	},
	"Named Entities"=>{
		"colour"=>"#5d4037",
		"name"=>"Named Entities: A real world objct",
		"underline"=>true
	},
	"Regex Matches"=>{
		"colour"=>"#616161",
		"name"=>"Regular Expressions: Text that matches a well defined pattern",
		"underline"=>false
	},
	"Compound Lexemes"=>{
		"colour"=>"#616161",
		"name"=>"Compound Lexemes: Phrases which are relating to the context",
		"underline"=>true
	},
	"skillsetProximities"=>{
		"colour"=>"#ffa726",
		"name"=>"Document Classification Keywords: Helped decide Document Classification",
		"underline"=>true
	},
	"skillsetClassification"=>{
		"colour"=>"#ffa726",
		"name"=>"Document Classification: The most likely type of document",
		"underline"=>false
	},
	"dictionaryProximities"=>{
		"colour"=>"#ce93d8",
		"name"=>"Dictionaries: Conversational Classification",
		"underline"=>false
	}
	
}
offsetOrder=["skillsetClassification","skillsetProximities","dictionaryProximities","Compound Lexemes","topicEntities","geoEntities","Named Entities","Regex Matches"]
examples={}
offsetOrder.each do | key |
	examples[key]=[]
end
startClock("Natural language processing")
#init
$nlpClient=NLP.new($config['nlp_graphQL']['baseUrl'],$config['nlp_graphQL']['username'],$config['nlp_graphQL']['password'])

$results.each_with_index do | result,index |
	begin
		blocks=result['text'].split(/(?:(?:[Ff]rom:.*?(?:[Ss]ent|[Dd]ate):.*?(?:[Tt]o:.*?[Ss]ubject:|[Ss]ubject:.*?[Tt]o:.*?>))|(?:On .*? at .*?@.*?\..*?wrote:))/)
		result['text']=blocks[0].strip()
		if(result['text'].strip().size < 20)
			if(blocks.size > 0)
				if(blocks[1].size > result['text'].size)
					result['text']=blocks[1].strip()
				end
			end
		end
		result['text']=cleanText(result['text'])
		
		result['task_id']=$nlpClient.processText(result['text'])
	rescue => ex
		puts ex.message
		puts ex.backtrace
	end
end

$results.each_with_index do | result,index |
	begin
		result['nlp']=$nlpClient.getSearchResult(result['task_id'])
		File.open($config['directories']['debug'] + '/nlp_' + $physicalEvidenceName + ".json", "w") { |f| f.write "#{result['nlp'].to_json}" }
	rescue => ex
		puts ex.message
		puts ex.backtrace
	end
end
endClock("Natural language processing")

def shorten(text,length)
	text.length > length ? "#{text[0...(length-3)]}..." : text
end

startClock("Replying and formatting response")
$results.each_with_index do | result,index |
	begin
		response=result['nlp']
		result['SkillSet']=""
		skillProx=-1
		if(response.has_key? 'skillsetProximities')
			if(!(response['skillsetProximities'].nil?))
				fallbackIfNotAbove40=nil
				response['skillsetProximities'].each do | record |
					if(!(record['skills'].nil?))
						record['skills'].each do | topicRecord |
							if(topicRecord['proximity'] > skillProx)
								skillProx=topicRecord['proximity']
								result['SkillSet']=topicRecord['skillName']
								result['skillSetName']=record['skillsetName']
								result['skillSetProximity']=topicRecord['proximity']
								fallbackIfNotAbove40='<tr><td width="40"><font size="-1">' + (topicRecord['proximity']*100).round(2).to_s + "&nbsp;%" + '</font></td><td width="230"><font size="-1">' + shorten(record['skillsetName'],40) + '</font></td><td width="230"><font size="-1">' + shorten(topicRecord['skillName'],40) + '</font></td></tr>'
							end
							if(result['tli'])
								if((topicRecord['proximity']*100) > 40)
									examples["skillsetClassification"].push('<tr><td width="40"><font size="-1">' + (topicRecord['proximity']*100).round(2).to_s + "&nbsp;%" + '</font></td><td width="230"><font size="-1">' + shorten(record['skillsetName'],40) + '</font></td><td width="230"><font size="-1">' + shorten(topicRecord['skillName'],40) + '</font></td></tr>')
								end
							end
						end
					end
				end
				if(result['tli'])
					if(!(fallbackIfNotAbove40.nil?))
						if(examples["skillsetClassification"].size == 0)
							examples["skillsetClassification"].push(fallbackIfNotAbove40)
						end
					end
				end

			end
		end
		dictProx=-1
		result['fraud']={}
		if(response.has_key? 'dictionaryProximities')
			if(!(response['dictionaryProximities'].nil?))
				response['dictionaryProximities'].each do | record |
					if(record['topicDictionaryName']=="Fraud Indicators")
						result['fraud']['group']=(record['proximity']*100).round(2)
						record['topicTypeProximities'].each do | topicRecord |
							result['fraud'][topicRecord['topicTypeName']]=(topicRecord['proximity']*100).round(2)
						end
					else
						if(!(record['topicTypeProximities'].nil?))
							record['topicTypeProximities'].each do | topicRecord |
								if(!(['Direct PII'].include? record['topicDictionaryName']))
									if(topicRecord['proximity'] > dictProx)
											dictProx=topicRecord['proximity']
											result['SubDictionary']=topicRecord['topicTypeName']
											result['SubDictionaryProximity']=topicRecord['proximity']
											result['Dictionary']=record['topicDictionaryName']
											result['DictionaryProximity']=record['proximity']
											if(result['tli'])
												if((dictProx*100) > 40)
													examples["dictionaryProximities"].push('<tr><td width="40"><font size="-1">' + (dictProx*100).round(2).to_s + "&nbsp;%" + '</font></td><td width="230"><font size="-1">' + shorten(result['Dictionary'],40) + '</font></td><td width="230"><font size="-1">' + shorten(result['SubDictionary'],40) + '</font></td></tr>')
												end
											end
									end
								end
							end
						end
					end
				end
			end
		end
		if(result['tli'])
			highlightBlob=""
			words=result['text'].split(' ').flat_map { |x| [x, ' '] }[0...-1] # in order to keep the space tokens as spaces
			
			
			
			offsets=[]
			["topicEntities","geoEntities"].each do | key |
				response[key].each do | topic |
					if((topic['relevance']*100) > 40)
						topic['lexemePositions'].each do | lexeme |
							position={
								"start"=>lexeme['offset'],
								"end"=>lexeme['offset'] + lexeme['length'],
								"type"=>key
							}
							phrase=nil
							if(topic.has_key? 'type')
								phrase=topic['type']['dictionaryName'] + "-" + topic['type']['name']
							else
								phrase=topic['dictionaryName'] + "-" + topic['mainName']['name']
							end
							phrase=shorten(phrase,40)
							if(!(topic['alias'].to_s.empty?))
								if(topic['alias'].start_with? 'http')
									phrase='<a href="' + topic['alias'] + '">' + phrase + '</a>'
								end
							end
							examples[key].push('<tr><td width="40"><font size="-1">' + (topic['relevance']*100).round(2).to_s + "&nbsp;%" + '</font></td><td width="230"><font size="-1">' + phrase + '</font></td><td width="230"><font size="-1">' + shorten(result["text"][lexeme['offset'],lexeme['length']].capitalize,40) + '</font></td></tr>')
							offsets.push(position)
						end
					end
				end
			end
			response["annotationSet"].keys.each do | key |
				response["annotationSet"][key].each do | annotation |
					examples[key].push('<tr><td width="40">&nbsp;</td><td width="230"><font size="-1">' + shorten(annotation['source'],40) + '</font></td><td width="230"><font size="-1">' + shorten(annotation["text"],40) + '</font></td></tr>')
					position={
						"start"=>annotation['start'],
						"end"=>annotation['end'],
						"type"=>key
					}
					offsets.push(position)
				end
			end
			
			if(response.has_key? 'keywords')
				if(response['keywords'].has_key? 'skillsets')
					response['keywords']['skillsets'].each do | mainTopic,values|
						response['keywords']['skillsets'][mainTopic].each do | record |
							proximity=(record['keywordsProximity']*100)
							proximityPhrase=nil
							if(proximity < 100)
								proximityPhrase=" #{proximity.round(2)}&nbsp;%"
							else
								proximityPhrase=proximity.round(2).to_s + "&nbsp;%"
							end
							if(proximity > 40)
								descriptor=mainTopic + "-" + record['className']
								record['keywords'].each do | keyword |
									position={
										"start"=>keyword['offset'],
										"end"=>keyword['offset'] + keyword['length'],
										"type"=>'skillsetProximities'
									}
									offsets.push(position)
									
									examples['skillsetProximities'].push('<tr><td width="40"><font size="-1">' + proximityPhrase + '</font></td><td width="230"><font size="-1">' + shorten(descriptor,40) + '</font></td><td width="230"><font size="-1">' + shorten(result["text"][keyword['offset'],keyword['length']].capitalize,40) + '</font></td></tr>')
								end
							end
						end
					end
				end
			end
			
			
			overalIndex=0
			fixedWidth=100
			thisLineSize=0
			textLine=nil
			lexemeLines={}
			words.each do | word |
				if((thisLineSize + word.size() > fixedWidth) || textLine.nil?)
					if(!(textLine.nil?))
						textLine=textLine + '<td width="620"></td></tr>'
						highlightBlob=highlightBlob + "\n" + textLine
						
						offsetOrder.each do | key |
							if(offsetTypes[key]['underline'])
								highlightBlob=highlightBlob + "\n" + lexemeLines[key] + '<td width="620"></td></tr>'
							end
						end
						
						 highlightBlob=highlightBlob + "\n<tr></tr></table>"
					end
					thisLineSize=0
					textLine='<table cellpadding="0" cellspacing="0" width="620" height="15" align="left" border="0"><tr height="7">'
					lexemeLines={}
					offsetOrder.each do | key |
						if(offsetTypes[key]['underline'])
							lexemeLines[key]='<tr height="1"><td></td></tr><tr height="2">'
						end
					end
				end
				thisLineSize=thisLineSize+word.size()
				fontColour=false
				actualWord=word.gsub(' ','&nbsp;')
								.gsub("<",'&lt;')
								.gsub('"','&quot;')
								.gsub(">",'&gt;')
	
				offsetOrder.each_with_index do | key,index |
					if(offsetTypes[key]['underline'])
						#this will underline whole words if a regex is smaller than the word... fine for most instances.
						if(offsets.select{|entry|entry['type']==key}.select{|entry|entry['start'] <= overalIndex}.select{|entry|entry['end'] >= overalIndex+word.size()}.size > 0)
							lexemeLines[key]=lexemeLines[key] + '<td bgcolor="' + offsetTypes[key]["colour"] + '"></td>'
							if(fontColour==false)
								fontColour=true
								actualWord='<font color="' + offsetTypes[key]["colour"] + '">' + actualWord + '</font>'
							end
						else
							lexemeLines[key]=lexemeLines[key] + '<td ></td>'
						end
					end
				end
				
				textLine=textLine + '<td style=" white-space: nowrap;overflow: hidden;text-overflow: ellipsis;">' + actualWord + '</td>'
				overalIndex=overalIndex+word.size()
			end
			textLine=textLine + '<td width="620"></td></tr>'
			highlightBlob=highlightBlob + "\n" + textLine
			
			offsetOrder.each do | key |
				if(offsetTypes[key]['underline'])
					highlightBlob=highlightBlob + "\n" + lexemeLines[key] + '<td width="620"></td></tr>'
				end
			end
			
			highlightBlob=highlightBlob + "\n<tr></tr></table>"
			
			
			
			
			result['html']=File.read($config['template'])
			
			result['html']=result['html'].gsub('<!--mainDocumentClassification-->',result['SkillSet'])
			result['html']=result['html'].gsub('<!--mainDocumentClassificationProximity-->',(result['skillSetProximity']*100).round(2).to_s + "&nbsp;%")
			result['html']=result['html'].gsub('<!--mainDocumentDictionary-->',result['Dictionary'])
			result['html']=result['html'].gsub('<!--mainDocumentDictionaryProximity-->',(result['DictionaryProximity']*100).round(2).to_s + "&nbsp;%")
			result['html']=result['html'].gsub('<!--subDocumentDictionary-->',result['SubDictionary'])
			result['html']=result['html'].gsub('<!--subDocumentDictionaryProximity-->',(result['SubDictionaryProximity']*100).round(2).to_s + "&nbsp;%")
			result['html']=result['html'].gsub('<!--highlightBlob-->',highlightBlob)
			
			if(result['fraud'].keys.size() >=4)
				if(result['fraud']['group'] > 60)
					fraudBlob='<tr><td bgcolor="#F7F8FA"><table cellpadding="0" cellspacing="10" width="640" height="60" align="left" border="0" borderColor="#81BEF1"><tr><td>'
					fraudBlob=fraudBlob + "Did you know... your communication has all the indicators of Fraud with a proximity of: <b>#{result['fraud']['group']}&nbsp;%</b><br><ul><li><b>#{result['fraud']['Rationalization']}&nbsp;%</b> Rationalization</li><li><b>#{result['fraud']['Pressure']}&nbsp;%</b> Pressure/Incentive</li><li><b>#{result['fraud']['Opportunity']}&nbsp;%</b> Opportunity</li></ul>"
					fraudBlob=fraudBlob + '</td></tr></table></td></tr>'
					result['html']=result['html'].gsub('<!-- fraud -->',fraudBlob)
				else
					result['html']=result['html'].gsub('<!-- fraud -->','<!-- Not enough fraud email' + "\n" + result['fraud'].to_json + '-->')
				end
			else
				result['html']=result['html'].gsub('<!-- fraud -->','<!-- Not fraud email' + "\n" + result['fraud'].to_json + '-->')
			end
			
			
			entities=response['annotationSet']["Named Entities"]
			if(!(entities.nil?))
				firstDate=entities.select{|e|e['source']=='Date'}.select{|e|e['text'].size > 4}.first()
				result['firstDate']=nil
				if(!(firstDate.nil?))
					result['firstDate']=firstDate['text']
				else
					firstDate=entities.select{|e|e['source']=='Time'}.select{|e|e['text'].size > 4}.first()
					if(!(firstDate.nil?))
						result['firstDate']=firstDate['text']
					end
				end
				firstEntity=entities.select{|e|!(["Date","Person","Cardinal","Percent","Time","Geo_Political_Entity","Facility","Quantity","Event"].include? e['source'])}.select{|e|e['text'].size > 2}.first()
				result['firstEntity']=nil
				if(!(firstEntity.nil?))
					result['firstEntity']="<b>" + firstEntity['text'] + "</b>"
				else
					firstEntity=entities.select{|e|!(["Date","Cardinal","Percent","Time","Geo_Political_Entity","Quantity","Event"].include? e['source'])}.select{|e|e['text'].size > 2}.first()
					if(!(firstEntity.nil?))
						result['firstEntity']="<b>" + firstEntity['text'] + "</b>"
					else					
						result['firstEntity']="<b>" + result['Dictionary'] + " - "  + result['SubDictionary'] + "</b>."
					end
				end
			end
			
			legendBlob=""
			
			offsetOrder.each do | key |
				if(examples[key].size > 0)
					annotationType=offsetTypes[key]
					legendBlob=legendBlob + '<tr height="10"><td width="20" bgcolor="' + annotationType["colour"] + '">&nbsp;</td><td>' + annotationType["name"] + '</td></tr><tr><td width="20"></td><td><table cellpadding="0" cellspacing="0" width="580" height="15" align="left" border="0">' + examples[key].uniq().sort().reverse().join("\n") + '</table></td></tr>'
				end
			end
			result['html']=result['html'].gsub('<!-- legend -->',legendBlob)
		end
		
	rescue => ex
		puts ex.message
		puts ex.backtrace
	end
end

response=""
fileOut=nil
begin
	tli=$results.select{|a|a['tli']==true}.first()
	File.open($config['directories']['debug'] + '/tli_' + $physicalEvidenceName + ".json", "w") { |f| f.write "#{tli.to_json}" }
	if(!(tli['internal']))
		raise StandardError.new "This address isn't on the permitted list"
	end
	response="Hi <b>#{tli['from']}</b>,<br><br>Thank you for your Email. "
	if(!(tli['firstEntity'].to_s.empty?))
		response=response + "I'd love to talk to you about #{tli['firstEntity']}, "
	end
	if(!(tli['firstDate'].to_s.empty?))
		response=response + " I know you mentioned <b>#{tli['firstDate']}</b> however "
	end
	response=response + "I'll be returning on the #{$config['returnDate']}."
	
	attachments=$results.select{|a|a['tli']==false}
	if(attachments.size() > 0)
		attachments.each_with_index do | attach,index |
			tli['replyBlock']=tli['replyBlock'] + "\n<br>Attachment:" + "<b>#{attach['name']}</b> is a <b>#{attach['kind']}</b> of type <b>#{attach['SkillSet']}</b> which discusses <b>#{attach['SubDictionary']}</b>."
			if(index==0)
				response=response + "<br><br>I'll check out your <b>#{attach['SkillSet']}</b> you attached when I get back."
			end
		end
	end
	
	response=response + "<br><br> We have a great unified platform here at Nuix. Extracting contextual meaning from different sources and types.<br>"
	response=response + "Looking forward to hearing what your thoughts are of my whizz bang out of office when I get back.<br><br>" 
	response=response + '<a href="https://nuix0-my.sharepoint.com/:v:/g/personal/cstiller01_nuix_com/ERiH6D_Tb_dLsS97r2BHbz4BGoSSI4oCJkeZAdjQju3F_w?e=TcRl1z">Leave feedback here</a><br><br>'

	if($config['dateSpecificFooter'].has_key? Time.now.strftime("%Y-%m-%d").to_s)
		response=response + $config['dateSpecificFooter'][Time.now.strftime("%Y-%m-%d").to_s] + "<br><br>"
	end
	
	tli['html']=tli['html'].gsub('<!--replyBlock-->',tli['replyBlock'])
	endClock("Replying and formatting response")
	timeTakenBlock=""
	$timesToFinish.sort_by{|key,details|-details['d']}.each do | key,details |
		timeTakenBlock=timeTakenBlock + "<tr><td>#{key}</td><td>#{details['p']}</td></tr>"
	end
	
	response=response + tli['html'].gsub('<!-- Time To Process -->',timeTakenBlock)
	File.open($config['directories']['out'] + '/' + $physicalEvidenceName + ".internal", "w") { |f| f.write "#{response}" }
	File.open($config['directories']['out'] + '_sample.html', "w") { |f| f.write "#{response}" }
rescue => ex
	puts ex.message
	puts ex.backtrace
	File.open($config['directories']['debug'] + '/error_' + $physicalEvidenceName + ".json", "w") { |f| f.write "#{ex.message}\n#{ex.backtrace}" }
	if(response=="")
		response="Thank you for your email. I will return #{$config['returnDate']}"
	end
	
	if(!(ARGV[0].nil?))
		File.open($config['directories']['out'] + '/' + $physicalEvidenceName + ".external", "w") { |f| f.write "#{response}" }
	end
end
if(!(ARGV[0].nil?))
	File.delete(physicalEvidencePath)
end

#Clean up
begin
	if(!($nlpClient.nil?))
		#not using project anymore... no cleanup?
	end
rescue => ex
	$logger.warn(ex.message)
	$logger.warn(ex.backtrace.to_s)
end
$nlpClient=nil