import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'user_state.dart';

class ApiService {
  // Fetch a list of objects from the API
  Future<List<T>> fetchList<T>(
    // The path to give to the API
    String endpoint,
    // Pass me the function you want called to turn the JSON into type T
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>?
        body, // Body can basically be any "object" that tell us what we want from a specific call
  }) async {
    // Get the full URL
    final url = Uri.parse("${dotenv.env['API_ROOT']!}$endpoint");
    // Current user
    String userId = await UserState().idAsync;
    try {
      /* This is the body we are actually going to send, 
      we are injecting the user id if it exists and making it if not */
      Map<String, dynamic> finalBody = body != null
          ? {
              ...body,
              'userId': userId
            } // Merge userId with the body if it's provided
          : {'userId': userId}; // Use the default myMap if body is null
      // Send the POST request
      final response = await http.post(
        url,
        // Need headers to tell the server info it needs
        headers: {
          'Content-Type': 'application/json',
        },
        // The body needs to be turned into JSON
        body: jsonEncode(finalBody),
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Parse the response body as JSON
        List<dynamic> responseData = jsonDecode(response.body);

        // Map each JSON object to a list of objects (T)
        /* This function fromJson HAS to take in one parameter, a Map<String, dynamic>
        and return a type T. Make sure we hold this true when we call it. When
        we give data to fromJson and handle it in creature_state, we are ASSUMING 
        that even though our response is a List<dynamic> that each thing in there (data)
        is going to be a Map<String, dynamic>. We know that we can assume each dynamic 
        will fit that pattern */
        return responseData.map((data) => fromJson(data)).toList();
      } else {
        throw Exception(
            'Failed to fetch data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
      rethrow; // Re-throw the exception to handle it upstream
    }
  }

  // Fetch a single object from the API
  Future<T> fetchSingle<T>(
    // Path
    String endpoint,
    // fromJson with same signature as before
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse("${dotenv.env['API_ROOT']!}$endpoint");
    String userId = await UserState().idAsync;

    try {
      // Inject the userid into the body if it exists, create if not
      Map<String, dynamic> finalBody = body != null
          ? {
              ...body,
              'userId': userId
            } // Merge userId with the body if it's provided
          : {'userId': userId}; // Use the default myMap if body is null
      // Send the POST request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(finalBody),
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        /* Parse the response body as JSON. We can make this response Map<String, dynamic> 
        now because we know it's only a single object */
        Map<String, dynamic> responseData = jsonDecode(response.body);

        // Deserialize the response into a single object (T)
        /* This is the way this method differs from the one above. Now, we 
        are returning the result of our fromJson without having to do anything 
        to it, because we only want one object  */
        return fromJson(responseData);
        // } else if (response.statusCode == 404) {
      } else {
        throw Exception(
            'Failed to fetch data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
      rethrow; // Re-throw the exception to handle it upstream
    }
  }

  /* Simple method for APIs that don't return data to parse,
  right now we use this when we catch a creature */
  Future<bool> postRequest(
    String endpoint, {
    Map<String, dynamic>? body, // body is a named parameter
  }) async {
    final url = Uri.parse("${dotenv.env['API_ROOT']!}$endpoint");
    String userId = await UserState().idAsync;

    try {
      // inject userid
      Map<String, dynamic> finalBody =
          body != null ? {...body, 'userId': userId} : {'userId': userId};
      // Send the POST request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(finalBody),
      );

      // Check if the request was successful (status code 200)
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
            'Failed to post data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
      return false; // Return false in case of an error
    }
  }
}
