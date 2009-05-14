// Control handlers and helper methods.
import flash.events.Event;

import mx.collections.ArrayCollection;
import mx.controls.LinkButton;
import mx.controls.Text;
import mx.managers.PopUpManager;

// Our selected filters.

private var _neighborhoodFilters:ArrayCollection = new ArrayCollection(); // Neighborhood filters
private var _genreFilters:ArrayCollection = new ArrayCollection(); // Genre filters
private var _minSelectedDate:Date = new Date(0); // Date filters
private var _maxSelectedDate:Date = new Date(0);
private var _minSelectedPrice:Number = 0; // Price filters
private var _maxSelectedPrice:Number = 0;

// Add or remove the given neighborhood filters.
private function recordNeighborhood(zip:String, selected:Boolean):void {
	_neighborhoodFilters.addItem({zip:zip, selected:selected});
}

// Initialize the neighborhood filters.
private function initializeNeighborhoodFilters():void {
	_neighborhoodFilters = new ArrayCollection();
}

// Add or remove the given genre filter.
private function recordGenre(genre:String, selected:Boolean):void {
	_genreFilters.addItem({genre:genre, selected:selected});
}

// Initialize the genre filters.
private function initializeGenreFilters():void {
	_genreFilters = new ArrayCollection();
}

// Run all of our filters, setting the display property on each MusicEvent,
// and displaying it on the map and graph.
private function runAllFilters():void {
	for each (var mev:MusicEvent in _events) {
		// Neighborhood filter.
		var inZip:Boolean = false;
		for each (var zipFilter:Object in _neighborhoodFilters) {
			if (mev.getVenue().getZip() == zipFilter.zip && zipFilter.selected) {
				inZip = true;
			}
		}
		// Genre filter.
		var inGenre:Boolean = false;
		for each (var genreFilter:Object in _genreFilters) {
			if (mev.getType() == genreFilter.genre && genreFilter.selected) {
				inGenre = true;
			}
		}
		// Time filter.
		var inTime:Boolean = false;
		if (_minSelectedDate != null && _maxSelectedDate != null && mev.getStartTime() != null &&
		    _minSelectedDate.valueOf() <= mev.getStartTime().valueOf() &&
		    _maxSelectedDate.valueOf() >= mev.getStartTime().valueOf()) {
			inTime = true;
		}
		// Price filter.
		var inPrice:Boolean = false;
		if (mev.getPrice() >= 0 &&
		    _minSelectedPrice <= mev.getPrice() &&
		    _maxSelectedPrice >= mev.getPrice()) {
			inPrice = true;
		}
		setDisplay(mev, (inZip && inGenre && inTime && inPrice));
	}
}

// Set the display property on the given MusicEvent, and
// show it on the map and graph.
private function setDisplay(mev:MusicEvent, selected:Boolean):void {
	if (mev.getDisplay() == false && selected) {
		showOnMap(mev);
		mev.showGraphItem(graph);
		mev.setDisplay(true);
	}
	if (mev.getDisplay() == true && !selected) {
		hideOnMap(mev);
		mev.hideGraphItem();
		mev.setDisplay(false);
	}
}

// Display the neighborhood select multi-check box.
private function neighborhoodSelect(linkButton:LinkButton, selectionList:Text):void {
	multiCheckBoxSelect(linkButton, selectionList, _neighborhoodsForControls,
	                    initializeNeighborhoodFilters, recordNeighborhood, runAllFilters,
	                    function(item:String):String { return "#000000" });
}

// Display the genre select multi-check box.
private function genreSelect(linkButton:LinkButton, selectionList:Text):void {
	multiCheckBoxSelect(linkButton, selectionList, _genresForControls,
	                    initializeGenreFilters, recordGenre, runAllFilters,
	                    function(item:String):String {
	                    	var color:int = getGenreColor(item);
	                    	var colorString:String = "#" + int2hex(color);
	                    	return colorString;
	                    });
}

// Display a generic multi-check box.
private function multiCheckBoxSelect(linkButton:LinkButton,
                                     selectionList:Text,
                                     dataProvider:ArrayCollection,
                                     callbackOnInitialize:Function,
                                     callbackOnRecord:Function,
                                     callbackOnComplete:Function,
                                     itemColor:Function):void {
	/* Open the TitleWindow container.
	   Cast the return value of the createPopUp() method
	   to our generic MultiCheckBoxWindow, the name of the 
	   component containing the TitleWindow container.
	*/
	var multiCheckBoxPopup:MultiCheckBoxWindow = 
		MultiCheckBoxWindow(PopUpManager.createPopUp(this, MultiCheckBoxWindow, true));

	// Different data providers could be passed in to this showWindow function.
	multiCheckBoxPopup.dataProvider = dataProvider;

	multiCheckBoxPopup.callbackOnInitialize = callbackOnInitialize;
	multiCheckBoxPopup.callbackOnRecord = callbackOnRecord;
	multiCheckBoxPopup.callbackOnComplete = callbackOnComplete;
	multiCheckBoxPopup.itemColor = itemColor;
 
	/* Pass a reference to the Text control to the TitleWindow container so that the 
	   TitleWindow container can return data to the main application.
	*/
	multiCheckBoxPopup.selections=selectionList;        
 
	// Calculate position of TitleWindow in Application's coordinates.
	// Position it a bit up and to the right of the LinkButton control.
	var point:Point = new Point();
	point.x=0;
	point.y=0;        
	point=linkButton.localToGlobal(point);
	multiCheckBoxPopup.x=point.x + 120;
	multiCheckBoxPopup.y=point.y - 40; 
}

// Draw our dual drag slider labels.
private function getSliderLabels(amount:Number, numberOfLabels:Number):Array
{
	var tmpArray:Array = new Array();
	tmpArray.push("");
	return tmpArray;
}

// Return the 'data tip' that is displayed when the time slider is used.
private function timeDataTipFunction(value:String):String
{
	return formatDate(calculateDateFromSlider(Number(value)));
}

// Return the 'data tim' that is displayed when the price slider is used.
private function priceDataTipFunction(value:String):String
{
	return formatPrice(calculatePriceFromSlider(Number(value)));
}

// Handler for a change on the time slider.
private function timeSliderChangeEvent(event:Event):void
{
	_minSelectedDate = calculateDateFromSlider(event.target.values[0]);
	_maxSelectedDate = calculateDateFromSlider(event.target.values[1]);
	timeSelected.text = "Time: from " + formatDate(_minSelectedDate) + " to " + formatDate(_maxSelectedDate);
	runAllFilters();
}

// Handler for a change on the price slider.
private function priceSliderChangeEvent(event:Event):void
{
	_minSelectedPrice = calculatePriceFromSlider(event.target.values[0]);
	_maxSelectedPrice = calculatePriceFromSlider(event.target.values[1]);
	priceSelected.text = "Price: from " + formatPrice(_minSelectedPrice) + " to " + formatPrice(_maxSelectedPrice);
	runAllFilters();
}

// Translate the date slider value to a Date.
private function calculateDateFromSlider(value:Number):Date {
	// The slider goes from 0 to 100.  Figure out the date
	// from the number given by scaling.
	if (getMaxDate() != null && getMinDate() != null) {
		var dateBits:Number = (getMaxDate().valueOf() - getMinDate().valueOf()) / 100.0;
		return new Date(getMinDate().valueOf() + (dateBits * value));
	}
	return null;
}

// Translate the price slider value to a price.
private function calculatePriceFromSlider(value:Number):Number {
	// The slider goes from 0 to 100.  Figure out the price
	// from the number given by scaling.
	var priceBits:Number = (getMaxPrice() - getMinPrice()) / 100.0;
	return getMinPrice() + (priceBits * value);
}

// Initialize the dates selected on the date slider.
private function initializeSelectedDates():void {
	_minSelectedDate = calculateDateFromSlider(25);
	_maxSelectedDate = calculateDateFromSlider(75);
	timeSelected.text = "Time: from " + formatDate(_minSelectedDate) + " to " + formatDate(_maxSelectedDate);
}

// Initialize the prices selected on the price slider.
private function initializeSelectedPrices():void {
	_minSelectedPrice = calculatePriceFromSlider(25);
	_maxSelectedPrice = calculatePriceFromSlider(75);
	priceSelected.text = "Price: from " + formatPrice(_minSelectedPrice) + " to " + formatPrice(_maxSelectedPrice);
}

// Format the given date as a string.
private function formatDate(date:Date):String {
	if (date == null) {
		return "";
	}
	var amOrPm:String = "AM";
	var hours:String = String(date.getHours());
	var minutes:String = String(date.getMinutes());
	if (date.getHours() > 12) {
		hours = String(date.getHours() - 12);
		amOrPm = "PM";
	}
	if (date.getHours() == 0) {
		hours = "12";
	}
	if (date.getMinutes() == 0) {
		minutes = "00";
	}
	if (date.getMinutes() >= 1 && date.getMinutes() <= 9) {
		minutes = "0" + String(date.getMinutes());
	}
	return date.getMonth() + "/" + date.getDate() + " " + hours + ":" + minutes + " " + amOrPm;
}

// Format the given price as a string.
private function formatPrice(price:Number):String {
	var decimalPl:Number = 2;
	var currencySymbol:String = "$";
	var decimalDelim:String = ".";

 	// Split the number into the whole and decimal (fractional) portions.
	var parts:Array = String(price).split(".");

	// Truncate or round the decimal portion, as directed.
    parts[1] = String(parts[1]).substr(0, 2);

	// Ensure that the decimal portion has the number of digits indicated. 
	// Requires the zeroFill(  ) method defined in Recipe 5.4.
	if (Number(parts[1]) < 10 && Number(parts[1]) > 0) {
		parts[1] = parts[1] + "0";
	}
	if (Number(parts[1]) == 0 || parts[1] == "NaN" || parts[1] == "un") {
		parts[1] = "00";
	}

	// Add a currency symbol and use String.join(  ) to merge the whole (dollar)
	// and decimal (cents) portions using the designated decimal delimiter.
	var output:String = currencySymbol + parts.join(decimalDelim);
	return output;
}

// Convert the given int to a hex string.
private function int2hex(val:int):String {
    var hex:String = '';
    var arr:String = 'FEDCBA';
    var len:uint = intBinLen(val);
    
    // Making sure it can at least match a single hex digit;
    
    if((len % 4) > 0){
        while((len % 4) > 0){
            len++;
        }
    }
    
    len /= 4;
    
    // Just for fun: making sure it is at least a byte, a word, or a dword. If you want just the exact hexadecimal count, comment this loop out.
    
    if((len % 4) > 0){
        while((len % 4) > 0){
            len++;
        }
    }
    
    for(var i:uint = 0; i < len; i++) {
        if(((val & (0x0F << (i * 4))) >> (i * 4)) > 9){
            hex = arr.charAt(15 - ((val & (0x0F << (i * 4))) >> (i * 4))) + hex;
        }
        else{
            hex = String(((val & (0x0F << (i * 4))) >> (i * 4))) + hex;
        }
    }
    
    if(hex == ''){
        hex = '000000';
    }
    
    return hex;
}

private function intBinLen(val:int):uint {
    var len:uint = 0;
    var check:Boolean = true;
    if(val != 0){
        len = 1;
        while(check){
            if((val >> len) == 0){
                check = false;
            }
            else{
                len++;
            }
        }
    }
    
    return len;
}
