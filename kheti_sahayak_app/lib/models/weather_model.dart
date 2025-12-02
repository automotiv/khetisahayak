
class WeatherForecast {
  final List<WeatherCondition> list;

  WeatherForecast({required this.list});

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    var list = (json['list'] as List)
        .map((item) => WeatherCondition.fromJson(item))
        .toList();

    return WeatherForecast(list: list);
  }
}

class WeatherCondition {
  final int dt;
  final Main main;
  final List<Weather> weather;
  final Clouds clouds;
  final Wind wind;
  final int visibility;
  final double pop;
  final Rain? rain;
  final Sys sys;
  final String dtTxt;

  WeatherCondition({
    required this.dt,
    required this.main,
    required this.weather,
    required this.clouds,
    required this.wind,
    required this.visibility,
    required this.pop,
    this.rain,
    required this.sys,
    required this.dtTxt,
  });

  factory WeatherCondition.fromJson(Map<String, dynamic> json) {
    return WeatherCondition(
      dt: json['dt'],
      main: Main.fromJson(json['main']),
      weather: (json['weather'] as List).map((i) => Weather.fromJson(i)).toList(),
      clouds: Clouds.fromJson(json['clouds']),
      wind: Wind.fromJson(json['wind']),
      visibility: json['visibility'],
      pop: (json['pop'] as num).toDouble(),
      rain: json['rain'] != null ? Rain.fromJson(json['rain']) : null,
      sys: Sys.fromJson(json['sys']),
      dtTxt: json['dt_txt'],
    );
  }
}

class Main {
  final double temp;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int pressure;
  final int seaLevel;
  final int grndLevel;
  final int humidity;
  final double tempKf;

  Main({
    required this.temp,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.pressure,
    required this.seaLevel,
    required this.grndLevel,
    required this.humidity,
    required this.tempKf,
  });

  factory Main.fromJson(Map<String, dynamic> json) {
    return Main(
      temp: (json['temp'] as num).toDouble(),
      feelsLike: (json['feels_like'] as num).toDouble(),
      tempMin: (json['temp_min'] as num).toDouble(),
      tempMax: (json['temp_max'] as num).toDouble(),
      pressure: json['pressure'],
      seaLevel: json['sea_level'],
      grndLevel: json['grnd_level'],
      humidity: json['humidity'],
      tempKf: (json['temp_kf'] as num).toDouble(),
    );
  }
}

class Weather {
  final int id;
  final String main;
  final String description;
  final String icon;

  Weather({required this.id, required this.main, required this.description, required this.icon});

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      id: json['id'],
      main: json['main'],
      description: json['description'],
      icon: json['icon'],
    );
  }
}

class Clouds {
  final int all;

  Clouds({required this.all});

  factory Clouds.fromJson(Map<String, dynamic> json) {
    return Clouds(all: json['all']);
  }
}

class Wind {
  final double speed;
  final int deg;
  final double gust;

  Wind({required this.speed, required this.deg, required this.gust});

  factory Wind.fromJson(Map<String, dynamic> json) {
    return Wind(
      speed: (json['speed'] as num).toDouble(),
      deg: json['deg'],
      gust: (json['gust'] as num).toDouble(),
    );
  }
}

class Rain {
  final double threeHour;

  Rain({required this.threeHour});

  factory Rain.fromJson(Map<String, dynamic> json) {
    return Rain(threeHour: (json['3h'] as num).toDouble());
  }
}

class Sys {
  final String pod;

  Sys({required this.pod});

  factory Sys.fromJson(Map<String, dynamic> json) {
    return Sys(pod: json['pod']);
  }
}

class UnifiedWeather {
  final double temp;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final double windSpeed;
  final String condition;
  final String icon;
  final String description;
  final double? uvi; // Only available in One Call
  final double? rainChance; // pop
  final bool isPrecision; // True if from One Call API
  final List<DailyForecast> dailyForecasts;

  UnifiedWeather({
    required this.temp,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.icon,
    required this.description,
    this.uvi,
    this.rainChance,
    this.isPrecision = false,
    this.dailyForecasts = const [],
  });

  // Factory for Standard 5-day/3-hour Forecast API
  factory UnifiedWeather.fromStandard(Map<String, dynamic> json) {
    final list = json['list'] as List;
    final current = list.first;
    final main = current['main'];
    final weather = current['weather'][0];
    final wind = current['wind'];
    
    // Approximate daily forecasts by taking every 8th item (24 hours / 3 hours = 8)
    List<DailyForecast> daily = [];
    for (var i = 0; i < list.length; i += 8) {
      daily.add(DailyForecast.fromStandard(list[i]));
    }

    return UnifiedWeather(
      temp: (main['temp'] as num).toDouble(),
      tempMin: (main['temp_min'] as num).toDouble(),
      tempMax: (main['temp_max'] as num).toDouble(),
      humidity: main['humidity'],
      windSpeed: (wind['speed'] as num).toDouble(),
      condition: weather['main'],
      icon: weather['icon'],
      description: weather['description'],
      rainChance: (current['pop'] as num?)?.toDouble(),
      isPrecision: false,
      dailyForecasts: daily,
    );
  }

  // Factory for One Call API
  factory UnifiedWeather.fromOneCall(Map<String, dynamic> json) {
    final current = json['current'];
    final weather = current['weather'][0];
    final dailyList = (json['daily'] as List).map((i) => DailyForecast.fromOneCall(i)).toList();

    return UnifiedWeather(
      temp: (current['temp'] as num).toDouble(),
      tempMin: (dailyList.first.tempMin),
      tempMax: (dailyList.first.tempMax),
      humidity: current['humidity'],
      windSpeed: (current['wind_speed'] as num).toDouble(),
      condition: weather['main'],
      icon: weather['icon'],
      description: weather['description'],
      uvi: (current['uvi'] as num?)?.toDouble(),
      isPrecision: true,
      dailyForecasts: dailyList,
    );
  }
}

class DailyForecast {
  final DateTime date;
  final double tempMin;
  final double tempMax;
  final String condition;
  final String icon;
  final double? rainChance;

  DailyForecast({
    required this.date,
    required this.tempMin,
    required this.tempMax,
    required this.condition,
    required this.icon,
    this.rainChance,
  });

  factory DailyForecast.fromStandard(Map<String, dynamic> json) {
    final main = json['main'];
    final weather = json['weather'][0];
    return DailyForecast(
      date: DateTime.parse(json['dt_txt']),
      tempMin: (main['temp_min'] as num).toDouble(),
      tempMax: (main['temp_max'] as num).toDouble(),
      condition: weather['main'],
      icon: weather['icon'],
      rainChance: (json['pop'] as num?)?.toDouble(),
    );
  }

  factory DailyForecast.fromOneCall(Map<String, dynamic> json) {
    final temp = json['temp'];
    final weather = json['weather'][0];
    return DailyForecast(
      date: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      tempMin: (temp['min'] as num).toDouble(),
      tempMax: (temp['max'] as num).toDouble(),
      condition: weather['main'],
      icon: weather['icon'],
      rainChance: (json['pop'] as num?)?.toDouble(),
    );
  }
}
