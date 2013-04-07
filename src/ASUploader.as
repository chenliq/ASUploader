package 
{
	
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.external.ExternalInterface;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.FileReferenceList;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLVariables;
	import flash.system.Security;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	
	
	
	
	public class ASUploader extends Sprite
	{
		public var btnTxtField:TextField = new TextField();
		
		public var fileMulti:FileReferenceList;
		public var fileOne:FileReference;
		public var setParamList:Array;
		
		public var request:URLRequest;
		public var boundary:String = "---BbC04y";// 数据分界符
		public var httpSeparator:String = "\r\n";
		public var fileQueue:Object = {};
		public var queueCounts:int = 0;
		
		// Values passed in from the HTML
		private var movieName:String;
		private var uploadUrl:String;
		private var lableText:String;
		private var textTopPadding:uint;
		private var textLeftPadding:uint;
		private var filePostName:String;
		private var postParams:Object;
		private var fileTypes:String;
		private var fileTypesDesc:String;
		private var fileTotalSize:int = 0;
		private var fileSizeLimit:int = 0;
		private var fileUploadLimit:int = 0;
		private var fileQueueLimit:int = 0;
		private var multiFiles:Boolean = true;
		private var autoUpload:Boolean = true;
		private var isDebug:Boolean = false;
		private var requeueOnError:Boolean = false;
		private var httpSuccess:Array = [];
		//		private var debugEnabled:Boolean;
		
		private var uploadCompleteHandler:String;
		
		
		public function ASUploader()
		{
			
			// 初始化参数
			this.movieName			= root.loaderInfo.parameters.movieName;
			this.uploadUrl			= root.loaderInfo.parameters.uploadUrl;
			this.lableText			= root.loaderInfo.parameters.lableText;
			this.textTopPadding		= uint(parseInt(root.loaderInfo.parameters.textTopPadding));
			this.textLeftPadding	= uint(parseInt(root.loaderInfo.parameters.textLeftPadding));
			this.filePostName		= root.loaderInfo.parameters.filePostName;
			this.fileTypes			= root.loaderInfo.parameters.fileTypes;
			this.fileTypesDesc		= root.loaderInfo.parameters.fileTypesDesc + " (" + this.fileTypes + ")";
			this.postParams			= {"_PostFromASUploader_": "1"};
			this.loadPostParams(root.loaderInfo.parameters.postParams);
			
			//Callback
			this.uploadCompleteHandler = root.loaderInfo.parameters.uploadCompleteHandler;
			
			if (!this.lableText) {
				this.lableText = "Please Select Files";
			}
			if (!this.fileTypes) {
				this.fileTypes = "*.*";
			}
			if (!this.fileTypesDesc) {
				this.fileTypesDesc = "All Files";
			}
			
			try {
				this.fileUploadLimit = int(root.loaderInfo.parameters.fileUploadLimit);
				if (this.fileUploadLimit < 0) this.fileUploadLimit = 0;
			} catch (ex:Object) {
				this.fileUploadLimit = 0;
			}
			
			try {
				this.fileQueueLimit = int(root.loaderInfo.parameters.fileQueueLimit);
				if (this.fileQueueLimit < 0) this.fileQueueLimit = 0;
			} catch (ex:Object) {
				this.fileQueueLimit = 0;
			}
			
			try {
				var multiFiles:String = root.loaderInfo.parameters.multiFiles;
				if (multiFiles == "false" || multiFiles == "0") {
					this.multiFiles = false;
				} else {
					this.multiFiles = true;
				}
			} catch (ex:Object) {
				this.multiFiles = false;
			}
			
			try {
				var autoUpload:String = root.loaderInfo.parameters.autoUpload;
				if (autoUpload == "false" || autoUpload == "0") {
					this.autoUpload = false;
				} else {
					this.autoUpload = true;
				}
			} catch (ex:Object) {
				this.autoUpload = false;
			}
			
			try {
				var isDebug:String = root.loaderInfo.parameters.isDebug;
				if (isDebug == "false" || isDebug == "0" || isDebug==null) {
					this.isDebug = false;
				} else {
					this.isDebug = true;
				}
			} catch (ex:Object) {
				this.isDebug = false;
			}
			
			Security.allowDomain("*");
			
			this.fileQueue = [];
			
			
			this.fileMulti = new FileReferenceList();
			this.fileOne = null;
			
			this.buttonMode = true;
			this.useHandCursor = true;
			
			this.stage.align		= "TL";
			this.stage.scaleMode	= "noScale";
			//			this.stage.addEventListener(Event.RESIZE, onResize);
			
			this.btnTxtField.htmlText = this.lableText;
			var format:TextFormat = new TextFormat("Georgia");
			format.size = 18;
			this.btnTxtField.setTextFormat(format);
			this.btnTxtField.autoSize	= "center";
			this.btnTxtField.x			= this.textLeftPadding;
			this.btnTxtField.y			= this.textTopPadding;
			this.btnTxtField.border		= false;
			this.btnTxtField.selectable	= false;
			this.btnTxtField.addEventListener(MouseEvent.CLICK, selectFiles); 
			addChild(this.btnTxtField);
			
			
			this.fileMulti.addEventListener(Event.COMPLETE, complete);
			this.fileMulti.addEventListener(Event.OPEN,open);
			//点击取消按钮会广播这个事件
			this.fileMulti.addEventListener(Event.CANCEL, cancel);
			this.fileMulti.addEventListener(Event.SELECT, select);
			this.fileMulti.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			
			//			onResize(null);
			
			
			// 设置javascript要回调的函数
			ExternalInterface.addCallback("sendPostDataToAs", addPostParams);
			ExternalInterface.addCallback("selectFiles", selectFiles);
			ExternalInterface.addCallback("upload", upload);
		}
		
		/**
		 * 打开选择文件对话框
		 */
		public function selectFiles(e:MouseEvent):void {
			
			this.queueCounts = 0;
			
			
			var allowed_file_types:String = "*.*";
			var allowed_file_types_desc:String = "All Files";
			
			if (this.fileTypes.length > 0) allowed_file_types = this.fileTypes;
			if (this.fileTypesDesc.length > 0)  allowed_file_types_desc = this.fileTypesDesc;
			
			try{
				if (this.multiFiles) {
					this.fileMulti.browse([new FileFilter(allowed_file_types_desc, allowed_file_types)]);
				} else {
					this.fileOne = new FileReference();
					this.fileOne.addEventListener(Event.SELECT, this.frefSelect);
					this.fileOne.addEventListener(Event.COMPLETE, frefComplete);
					this.fileOne.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
					this.fileOne.browse([new FileFilter(allowed_file_types_desc, allowed_file_types)]);
				}
			} catch (ex:Error) {
				this.debug("Exception: " + ex.toString());
			}
		}
		
		/**
		 * 选择单个文件
		 */
		private function frefSelect(e:Event):void {
			this.fileOne.load();
		}
		
		/**
		 * IO失败
		 */
		private function ioErrorHandler(event:IOErrorEvent):void {
			this.debug("ioErrorHandler: " + event);
		}
		
		/**
		 * 设置参数
		 */
		public function addPostParams(params:Object):void {
			for (var key:String in params) {
				this.postParams[key] = params[key];
			}
		}
		
		/**
		 * 上传已选文件
		 */
		public function upload():void {
			this.request = new URLRequest(uploadUrl);
			this.request.method = "POST";
			this.setHeader("Cache-Control", "no-cache");
			this.setHeader("Content-Type", "multipart/form-data;boundary=" + boundary);
			
			this.request.data = new ByteArray;
			this.writeBodyData(this.fileQueue);
			this.writeBodyData(this.postParams);
			this.request.data.writeUTFBytes("--" + boundary + "--");
			this.request.data.writeUTFBytes(httpSeparator);
			
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = "binary";
			loader.addEventListener(Event.COMPLETE, uploadComplete);
			loader.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			
			
			loader.load(request);
			
		}
		
		private function progressHandler(event:ProgressEvent):void {
			this.debug("progressHandler loaded:" + event.bytesLoaded + " total: " + event.bytesTotal);
		}
		
		
		
		/**
		 * 上传完成处理方法
		 */
		public function uploadComplete(event:Event):void {
			// JS有上传完成回调函数,则调用
			if (this.uploadCompleteHandler) {
				// event.target.data.toString() 服务端返回的字符串
				this.debug(event.target.data.toString());
				ExternalInterface.call(this.uploadCompleteHandler, event.target.data.toString());
			}
		}
		
		
		
		public function complete(e:Event):void {
		}
		
		public function open(e:Event):void {
		}
		
		public function cancel(e:Event):void {
		}
		
		public function select(e:Event):void {
			for(var i:uint=0;i<this.fileMulti.fileList.length;i++)
			{
				this.fileMulti.fileList[i].addEventListener(Event.COMPLETE, frefComplete);
				this.fileMulti.fileList[i].addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
				this.fileMulti.fileList[i].load();
			}
		}
		
		/**
		 * 图片选择完成后处理
		 */
		public function frefComplete(e:Event):Boolean {
			
			var contentType:String = "unknow";
			
			if (e.target.type == ".gif") {
				contentType = "image/gif";
			} else if (e.target.type == ".png") {
				contentType = "image/png";
			} else if (e.target.type == ".jpg") {
				contentType = "image/jpeg";
			}
			if (e.target.size == 0) {
				return false;
			}
			this.fileTotalSize += e.target.size;
			
			if (this.fileSizeLimit > 0 && this.fileTotalSize > this.fileSizeLimit) {
				return false;
			}
			
			var mimeType:String = "text/plain";
			var byte1:int = e.target.data.readUnsignedByte();
			var byte2:int = e.target.data.readUnsignedByte();
			if (e.target.data is ByteArray) {
				mimeType = getMimeTypeFromBytes(byte1, byte2);
				this.fileQueue[queueCounts] = {"mimeType": mimeType, "filename":e.target.name, "data":e.target.data};
				this.queueCounts ++;
			} else {//可能上传文本文件
				this.fileQueue[queueCounts] = {"mimeType": mimeType, "filename":e.target.name, "data":e.target.data};
				this.queueCounts ++;
			}
			
			if (this.fileQueueLimit>0 && this.queueCounts > this.fileQueueLimit) {
				return false;
			} else if (this.autoUpload)  {
				this.upload();
			}
			return true;
		}
		
		/**
		 * 根据文件头两字节来判断MimeType类型
		 */
		public function getMimeTypeFromBytes(byte1:int, byte2:int):String {
			var code:String = byte1+""+byte2;
			var mimeType:String = "UnKnow";
			switch (code) {
				case "7790":
					mimeType = 'application/octet-stream';
				case "6787":
					mimeType = 'application/x-shockwave-flash';
					break;
				case "8075":
					mimeType = 'application/bmp';
					break;
				case "6677":
					mimeType = 'image/bmp';
					break;
				case "7173":
					mimeType = 'image/gif';
					break;
				case "255216":
					mimeType = 'image/jpeg';
					break;
				case "13780":
					mimeType = 'image/png';
					break;
				case "79103":
					mimeType = 'application/ogg';
					break;
			}
			return mimeType;
		}
		
		public function setHeader(headerName:String, headerValue:String):void {
			request.requestHeaders.push(new URLRequestHeader(headerName, headerValue));
		}
		
		/**
		 * 向发送请求类写入二进制数据
		 * 
		 */
		public function writeBodyData(srcData:Object):void	{
			var key:String;
			for (key in srcData)
			{
				if (srcData[key] is String)
				{
					this.request.data.writeUTFBytes("--" + boundary);
					this.request.data.writeUTFBytes(httpSeparator);
					this.request.data.writeUTFBytes("Content-Disposition: form-data; name=\"" + key + "\"");
					this.request.data.writeUTFBytes(httpSeparator);
					this.request.data.writeUTFBytes(httpSeparator);
					this.request.data.writeUTFBytes(srcData[key]);
					this.request.data.writeUTFBytes(httpSeparator);
				}
				else if (srcData[key].data is ByteArray)
				{
					this.request.data.writeUTFBytes("--" + boundary);
					this.request.data.writeUTFBytes(httpSeparator);
					this.request.data.writeUTFBytes("Content-Disposition: form-data; name=\"" + key + "\"; filename=\"" + srcData[key].filename + "\"");
					this.request.data.writeUTFBytes(httpSeparator);
					this.request.data.writeUTFBytes("Content-Type: " + srcData[key].mimeType);//Content-Type
					this.request.data.writeUTFBytes(httpSeparator);
					this.request.data.writeUTFBytes(httpSeparator);
					this.request.data.writeBytes(srcData[key].data, 0, srcData[key].data.length);
					this.request.data.writeUTFBytes(httpSeparator);
				}
			}
		}
		
		/**
		 * 加载要POST的参数
		 */
		private function loadPostParams(param_string:String):void {
			if (param_string != null) {
				var name_value_pairs:Array = param_string.split("&");
				
				var key:String = "";
				var val:String = "";
				
				for (var i:Number = 0; i < name_value_pairs.length; i++) {
					var name_value:String = String(name_value_pairs[i]);
					var index_of_equals:Number = name_value.indexOf("=");
					if (index_of_equals > 0) {
						key = decodeURIComponent(name_value.substring(0, index_of_equals));
						val = decodeURIComponent(name_value.substr(index_of_equals + 1));
						this.postParams[key] = val;
					}
				}
			}
		}
		
		public function debug(debugInfo:String):void {
			if (this.isDebug)
			{
				trace(debugInfo);
			}
		}
		
	}
	
	
}
