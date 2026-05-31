import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/errors/app_exception.dart';
import 'models/visual_search_result.dart';

part 'visual_search_provider.g.dart';

enum VisualSearchStatus { idle, capturing, processing, results, failed }

class VisualSearchState {
  final VisualSearchStatus status;
  final VisualSearchData? data;
  final AppException? error;

  const VisualSearchState({
    this.status = VisualSearchStatus.idle,
    this.data,
    this.error,
  });

  VisualSearchState copyWith({
    VisualSearchStatus? status,
    VisualSearchData? data,
    AppException? error,
  }) {
    return VisualSearchState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}

@riverpod
class VisualSearchNotifier extends _$VisualSearchNotifier {
  @override
  VisualSearchState build() {
    return const VisualSearchState();
  }

  Future<void> processImage(String imagePath) async {
    state = state.copyWith(status: VisualSearchStatus.processing);

    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
      });

      final res = await ApiClient().request<VisualSearchData>(
        path: '/visual-search',
        method: 'POST',
        data: formData,
        parser: (data) => VisualSearchData.fromJson(data as Map<String, dynamic>),
      );

      if (res is ApiSuccess<VisualSearchData>) {
        state = state.copyWith(
          status: VisualSearchStatus.results,
          data: res.data,
        );
      } else if (res is ApiFailure<VisualSearchData>) {
        final err = res.statusCode == 429 
            ? const RateLimitError('api') 
            : BackendError(res.message);
        state = state.copyWith(
          status: VisualSearchStatus.failed,
          error: err,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: VisualSearchStatus.failed,
        error: BackendError(e.toString()),
      );
    }
  }

  Future<void> pickFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        await processImage(image.path);
      }
    } catch (e) {
      state = state.copyWith(
        status: VisualSearchStatus.failed,
        error: BackendError(e.toString()),
      );
    }
  }

  void reset() {
    state = const VisualSearchState();
  }
}
