import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/category_repository.dart';
import 'category_event.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository categoryRepository;

  CategoryBloc({required this.categoryRepository}) : super(CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
  }

  Future<void> _onLoadCategories(LoadCategories event, Emitter<CategoryState> emit) async {
    emit(CategoryLoading());
    try {
      final categories = await categoryRepository.getCategories();
      emit(CategoryLoaded(categories));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }
}
